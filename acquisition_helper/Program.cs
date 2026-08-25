using System;
using System.IO;
using System.Windows.Forms;

namespace HiHat.AcquisitionHelper
{
    internal static class Program
    {
        internal static void Log(string message, Exception error)
        {
            var folder = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),
                "HiHat");
            Directory.CreateDirectory(folder);
            File.AppendAllText(
                Path.Combine(folder, "acquisition-helper.log"),
                DateTime.UtcNow.ToString("O") + " " + message + Environment.NewLine + error + Environment.NewLine);
        }

        [STAThread]
        private static void Main()
        {
            try
            {
                Application.EnableVisualStyles();
                Application.SetCompatibleTextRenderingDefault(false);
                using (var host = new BrowserHost())
                using (var ipc = new IpcServer(host, 8876))
                {
                    ipc.Start();
                    Application.Run(host);
                }
            }
            catch (Exception error)
            {
                Log("Helper startup failed", error);
            }
        }
    }
}
