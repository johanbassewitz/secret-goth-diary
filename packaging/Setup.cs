using System;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows.Forms;

internal static class Setup
{
    [STAThread]
    private static int Main(string[] args)
    {
        string staging = Path.Combine(Path.GetTempPath(), "SecretGothDiary-" + Guid.NewGuid().ToString("N"));
        try
        {
            Directory.CreateDirectory(staging);
            foreach (string name in new[] { "diary.zip", "Install.ps1" })
            {
                using (Stream input = Assembly.GetExecutingAssembly().GetManifestResourceStream(name))
                using (FileStream output = File.Create(Path.Combine(staging, name)))
                {
                    if (input == null) throw new InvalidOperationException("Setup payload is missing.");
                    input.CopyTo(output);
                }
            }
            ProcessStartInfo start = new ProcessStartInfo();
            start.FileName = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.System), @"WindowsPowerShell\v1.0\powershell.exe");
            start.Arguments = "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File \"" + Path.Combine(staging, "Install.ps1") + "\"";
            start.UseShellExecute = false;
            start.CreateNoWindow = true;
            using (Process install = Process.Start(start))
            {
                install.WaitForExit();
                return install.ExitCode;
            }
        }
        catch (Exception error)
        {
            MessageBox.Show(error.Message, "Secret Goth Diary - Setup", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return 1;
        }
        finally
        {
            // staging is a fresh GUID directory created by this process.
            try { if (Directory.Exists(staging)) Directory.Delete(staging, true); } catch { }
        }
    }
}
