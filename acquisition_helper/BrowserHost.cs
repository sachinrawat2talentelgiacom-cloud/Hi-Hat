using Microsoft.Web.WebView2.Core;
using Microsoft.Web.WebView2.WinForms;
using System;
using System.Collections.Concurrent;
using System.IO;
using System.Threading.Tasks;
using System.Windows.Forms;

namespace HiHat.AcquisitionHelper
{
    internal sealed class BrowserHost : Form
    {
        private readonly WebView2 browser = new WebView2();
        private readonly ConcurrentDictionary<string, AcquisitionJob> jobs =
            new ConcurrentDictionary<string, AcquisitionJob>();
        private AcquireRequest activeRequest;
        private bool downloadInvoked;
        private Timer pageTimer;
        private readonly bool debugVisible;

        public bool WebViewReady { get; private set; }
        public bool DebugVisible => debugVisible;
        public string StartupError { get; private set; }

        public BrowserHost()
        {
            debugVisible = !string.Equals(
                Environment.GetEnvironmentVariable("HI_HAT_HELPER_HIDDEN"),
                "1",
                StringComparison.Ordinal);
            Text = "Hi Hat Provider Browser — visible debug mode";
            Width = 1120;
            Height = 760;
            StartPosition = FormStartPosition.CenterScreen;
            browser.Dock = DockStyle.Fill;
            Controls.Add(browser);
            Shown += async (_, __) =>
            {
                try
                {
                    await InitializeAsync();
                }
                catch (Exception error)
                {
                    StartupError = error.Message;
                    Program.Log("WebView2 initialization failed", error);
                }
            };
            FormClosing += (_, args) =>
            {
                if (args.CloseReason == CloseReason.UserClosing)
                {
                    args.Cancel = true;
                    Hide();
                }
            };
        }

        private async Task InitializeAsync()
        {
            var profile = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "HiHat",
                "BrowserProfile");
            Directory.CreateDirectory(profile);
            var environment = await CoreWebView2Environment.CreateAsync(null, profile);
            await browser.EnsureCoreWebView2Async(environment);
            browser.CoreWebView2.DownloadStarting += OnDownloadStarting;
            browser.CoreWebView2.NavigationCompleted += OnNavigationCompleted;
            browser.CoreWebView2.Settings.AreDevToolsEnabled = true;
            WebViewReady = true;
            if (!debugVisible) Hide();
        }

        public AcquisitionJob Start(AcquireRequest request)
        {
            if (!WebViewReady)
                return Failed(request.acquisition_id, "BROWSER_START_FAILED", "WebView2 is still starting");
            if (string.IsNullOrWhiteSpace(request.acquisition_id) ||
                string.IsNullOrWhiteSpace(request.provider_track_id))
                return Failed(request.acquisition_id, "TRACK_MATCH_FAILED", "Track identity is missing");

            var job = new AcquisitionJob
            {
                acquisition_id = request.acquisition_id,
                status = "OPENING_SOURCE",
                title = request.title,
                artist = request.artist,
                updated_at = DateTime.UtcNow,
            };
            if (!jobs.TryAdd(job.acquisition_id, job)) return jobs[job.acquisition_id];
            activeRequest = request;
            downloadInvoked = false;
            BeginInvoke(new Action(() =>
            {
                if (debugVisible)
                {
                    Show(); // Visible debug mode remains mandatory until live validation passes.
                    Activate();
                }
                browser.CoreWebView2.Navigate(
                    "https://monochrome.tf/track/" + Uri.EscapeDataString(request.provider_track_id));
            }));
            return job;
        }

        public AcquisitionJob Get(string id)
        {
            AcquisitionJob job;
            return jobs.TryGetValue(id, out job) ? job : null;
        }

        public AcquisitionJob Cancel(string id)
        {
            var job = Get(id);
            if (job == null) return null;
            job.status = "CANCELLED";
            job.updated_at = DateTime.UtcNow;
            BeginInvoke(new Action(() => browser.CoreWebView2?.Stop()));
            return job;
        }

        public void ShowAuthorization()
        {
            BeginInvoke(new Action(() => { Show(); Activate(); }));
        }

        public async Task ResetSessionAsync()
        {
            if (!WebViewReady) throw new InvalidOperationException("WebView2 is still starting");
            await browser.CoreWebView2.Profile.ClearBrowsingDataAsync();
        }

        private void OnNavigationCompleted(object sender, CoreWebView2NavigationCompletedEventArgs args)
        {
            if (activeRequest == null || IsTerminal(Get(activeRequest.acquisition_id))) return;
            var job = Get(activeRequest.acquisition_id);
            if (!args.IsSuccess)
            {
                Fail(job, "SOURCE_UNAVAILABLE", "Monochrome navigation failed");
                return;
            }
            pageTimer?.Stop();
            pageTimer = new Timer { Interval = 1500 };
            pageTimer.Tick += async (_, __) => await InspectAndDownloadAsync();
            pageTimer.Start();
        }

        private async Task InspectAndDownloadAsync()
        {
            if (activeRequest == null || downloadInvoked) return;
            var job = Get(activeRequest.acquisition_id);
            if (job == null || IsTerminal(job)) return;
            var source = browser.Source;
            var expected = "/track/" + activeRequest.provider_track_id;
            if (source == null || source.Scheme != "https" || source.Host != "monochrome.tf" || source.AbsolutePath != expected)
            {
                job.status = "AUTH_REQUIRED";
                job.updated_at = DateTime.UtcNow;
                ShowAuthorization();
                return;
            }
            var state = await browser.ExecuteScriptAsync(@"
                (() => {
                  const auth = document.querySelector(
                    'iframe[src*=""turnstile""], input[name=""cf-turnstile-response""], #challenge-form');
                  if (auth) return 'AUTH_REQUIRED';
                  const button = document.querySelector('#download-track-btn');
                  if (!button || button.offsetParent === null) return 'WAITING';
                  button.click();
                  return 'STARTED';
                })();");
            if (state.Contains("AUTH_REQUIRED"))
            {
                job.status = "AUTH_REQUIRED";
                ShowAuthorization();
            }
            else if (state.Contains("STARTED"))
            {
                downloadInvoked = true;
                job.status = "STARTING_DOWNLOAD";
                job.updated_at = DateTime.UtcNow;
                pageTimer.Stop();
            }
            else
            {
                job.status = "MATCHING_TRACK";
                job.updated_at = DateTime.UtcNow;
            }
        }

        private void OnDownloadStarting(object sender, CoreWebView2DownloadStartingEventArgs args)
        {
            if (activeRequest == null) return;
            var job = Get(activeRequest.acquisition_id);
            if (job == null || IsTerminal(job)) return;
            var folder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "HiHat", "Acquisitions", activeRequest.acquisition_id);
            Directory.CreateDirectory(folder);
            var destination = Path.Combine(folder, "incoming.flac");
            args.ResultFilePath = destination;
            args.Handled = true;
            var operation = args.DownloadOperation;
            job.status = "DOWNLOADING";
            job.local_path = destination;
            job.bytes_total = operation.TotalBytesToReceive;
            job.updated_at = DateTime.UtcNow;
            operation.BytesReceivedChanged += (_, __) =>
            {
                job.bytes_received = operation.BytesReceived;
                job.updated_at = DateTime.UtcNow;
            };
            operation.StateChanged += (_, __) =>
            {
                job.updated_at = DateTime.UtcNow;
                if (operation.State == CoreWebView2DownloadState.Completed)
                    job.status = "READY_FOR_BACKEND";
                else if (operation.State == CoreWebView2DownloadState.Interrupted)
                    Fail(job, "DOWNLOAD_INTERRUPTED", operation.InterruptReason.ToString());
            };
        }

        private static bool IsTerminal(AcquisitionJob job) => job == null ||
            job.status == "READY_FOR_BACKEND" || job.status == "FAILED" || job.status == "CANCELLED";

        private AcquisitionJob Failed(string id, string code, string message)
        {
            var job = new AcquisitionJob { acquisition_id = id, status = "FAILED" };
            Fail(job, code, message);
            if (!string.IsNullOrWhiteSpace(id)) jobs[id] = job;
            return job;
        }

        private static void Fail(AcquisitionJob job, string code, string message)
        {
            job.status = "FAILED";
            job.error_code = code;
            job.error_message = message;
            job.updated_at = DateTime.UtcNow;
        }
    }
}
