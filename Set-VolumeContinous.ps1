Function Set-VolumeContinuous
{
    Param
    (
        [ValidateScript({
            if($_ -lt 0 -or $_ -gt 1) {Throw "Target Volume cannot be less than 0 or greater than 1"}
            else {$true}
        })]
        [float]$TargetVolume = 0.1,
        
        [ValidateScript({
            if($_ -le 0 -or $_ -gt [audio]::Volume) {Throw "Decrement Amount cannot be less than 0 or larger than current Volume: $([audio]::Volume)"}
            else {$true}
        })]
        [float]$DecrementAmount = .005,
        
        [ValidateScript({
            if($_ -le 0) {Throw "Interval cannot be 0 or less"}
            else {$true}
        })]
        [int]$DecrementInterval = 240
    )

    # Type taken from https://stackoverflow.com/questions/21355891/change-audio-level-from-powershell
    Add-Type -TypeDefinition @'
using System.Runtime.InteropServices;

[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
  // f(), g(), ... are unused COM method slots. Define these if you care
  int f(); int g(); int h(); int i();
  int SetMasterVolumeLevelScalar(float fLevel, System.Guid pguidEventContext);
  int j();
  int GetMasterVolumeLevelScalar(out float pfLevel);
  int k(); int l(); int m(); int n();
  int SetMute([MarshalAs(UnmanagedType.Bool)] bool bMute, System.Guid pguidEventContext);
  int GetMute(out bool pbMute);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
  int Activate(ref System.Guid id, int clsCtx, int activationParams, out IAudioEndpointVolume aev);
}
[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
  int f(); // Unused
  int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice endpoint);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")] class MMDeviceEnumeratorComObject { }

public class Audio {
  static IAudioEndpointVolume Vol() {
    var enumerator = new MMDeviceEnumeratorComObject() as IMMDeviceEnumerator;
    IMMDevice dev = null;
    Marshal.ThrowExceptionForHR(enumerator.GetDefaultAudioEndpoint(/*eRender*/ 0, /*eMultimedia*/ 1, out dev));
    IAudioEndpointVolume epv = null;
    var epvid = typeof(IAudioEndpointVolume).GUID;
    Marshal.ThrowExceptionForHR(dev.Activate(ref epvid, /*CLSCTX_ALL*/ 23, 0, out epv));
    return epv;
  }
  public static float Volume {
    get {float v = -1; Marshal.ThrowExceptionForHR(Vol().GetMasterVolumeLevelScalar(out v)); return v;}
    set {Marshal.ThrowExceptionForHR(Vol().SetMasterVolumeLevelScalar(value, System.Guid.Empty));}
  }
  public static bool Mute {
    get { bool mute; Marshal.ThrowExceptionForHR(Vol().GetMute(out mute)); return mute; }
    set { Marshal.ThrowExceptionForHR(Vol().SetMute(value, System.Guid.Empty)); }
  }
}
'@
    $counter = 0

    while($true)
    {
        $counter++;
        
        $Output = "Run number $counter | " + 
                  "Target Volume: $([Math]::Round($TargetVolume * 100, 0))% | " +
                  "Decrement Amount: $([Math]::Round($DecrementAmount * 100, 1))% | " +
                  "Decrement Interval: $DecrementInterval seconds";
        Write-Host $Output

        if([audio]::Volume -ge $TargetVolume)
        {
            [audio]::Volume = [audio]::Volume - $DecrementAmount;    
            Write-Host "Volume is set to: $([Math]::Round([audio]::Volume * 100, 1))"
        } 
        else 
        {
            Write-Host "Volume not changed, hit target of $TargetVolume"
        }

        Start-Sleep -Seconds $DecrementInterval
    }
}