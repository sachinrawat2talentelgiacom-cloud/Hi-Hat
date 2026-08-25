using System;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;
using System.Web.Script.Serialization;

namespace HiHat.AcquisitionHelper
{
    internal sealed class IpcServer : IDisposable
    {
        private readonly BrowserHost host;
        private readonly HttpListener listener = new HttpListener();
        private readonly JavaScriptSerializer json = new JavaScriptSerializer();
        private CancellationTokenSource cancellation;

        public IpcServer(BrowserHost host, int port)
        {
            this.host = host;
            listener.Prefixes.Add("http://127.0.0.1:" + port + "/");
        }

        public void Start()
        {
            cancellation = new CancellationTokenSource();
            listener.Start();
            ThreadPool.QueueUserWorkItem(_ => Loop());
        }

        private void Loop()
        {
            while (!cancellation.IsCancellationRequested)
            {
                try { Handle(listener.GetContext()); }
                catch (HttpListenerException) when (cancellation.IsCancellationRequested) { }
                catch { }
            }
        }

        private void Handle(HttpListenerContext context)
        {
            try
            {
                var path = context.Request.Url.AbsolutePath.Trim('/');
                object result;
                if (context.Request.HttpMethod == "GET" && path == "health")
                    result = new { status = host.StartupError != null ? "failed" : host.WebViewReady ? "ready" : "starting", webview_ready = host.WebViewReady, profile_loaded = host.WebViewReady, debug_visible = host.DebugVisible, error = host.StartupError };
                else if (context.Request.HttpMethod == "POST" && path == "acquire")
                    result = host.Start(Read<AcquireRequest>(context.Request));
                else if (context.Request.HttpMethod == "GET" && path.StartsWith("status/"))
                    result = host.Get(path.Substring("status/".Length));
                else if (context.Request.HttpMethod == "POST" && path.StartsWith("cancel/"))
                    result = host.Cancel(path.Substring("cancel/".Length));
                else if (context.Request.HttpMethod == "POST" && path == "show-auth")
                { host.ShowAuthorization(); result = new { status = "shown" }; }
                else if (context.Request.HttpMethod == "POST" && path == "reset-session")
                { host.ResetSessionAsync().GetAwaiter().GetResult(); result = new { status = "reset" }; }
                else
                { context.Response.StatusCode = 404; result = new { error = "not_found" }; }
                Write(context.Response, result);
            }
            catch (Exception error)
            {
                context.Response.StatusCode = 500;
                Write(context.Response, new { error = "helper_error", message = error.Message });
            }
        }

        private T Read<T>(HttpListenerRequest request)
        {
            using (var reader = new StreamReader(request.InputStream, request.ContentEncoding))
                return json.Deserialize<T>(reader.ReadToEnd());
        }

        private void Write(HttpListenerResponse response, object value)
        {
            var bytes = Encoding.UTF8.GetBytes(json.Serialize(value));
            response.ContentType = "application/json";
            response.ContentEncoding = Encoding.UTF8;
            response.ContentLength64 = bytes.Length;
            response.OutputStream.Write(bytes, 0, bytes.Length);
            response.Close();
        }

        public void Dispose()
        {
            cancellation?.Cancel();
            if (listener.IsListening) listener.Stop();
            listener.Close();
        }
    }
}
