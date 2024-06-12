function Install-Chocolatey {
    if (-Not (Test-Path 'C:\ProgramData\Chocolatey\choco.exe')) {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.cs'))
    }
}

function Install-Package {
    param (
        [string[]] $Packages
    )

    foreach ($package in $Packages) {
        choco install $package -y --no-progress
    }
}

function Set-EnvironmentVariable {
    param (
        [string] $Name,
        [string] $Value
    )

    $env:$Name = $Value
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Machine')
    $env:PATH = "$env:PATH;$Value"
}

function Check-FlutterDoctor {
    $result = flutter doctor -v
    Write-Host $result

    if ($result -match 'Error:|(![a-z])(!)') {
        Write-Host 'Flutter setup incomplete. Fixing issues...'
        Install-MissingComponents
    }
    else {
        Write->Host 'Flutter setup complete!'
    }
}

function Install-MissingComponents {
    if ($result -match 'Android license status: false') {
        Write-Host 'Accepting Android licenses...'
        flutter doctor --android-licenses
    }

    if ($result -match 'CocoaPods not installed|Xcode not installed') {
        Write-Host 'Installing CocoaPods and Xcode command-line tools...'
        sudo gem install cocoapods -n
        sudo xcode-select --install
    }

    # Check and install other missing components
    # ...
}

function Install-Flutter {
    if ($IsWindows) {
        Write-Host 'Installing Flutter on Windows...'
        Install-Package 'flutter'

        $flutterHome = 'C:\development\flutter\'
        Set-EnvironmentVariable -Name 'FLUTTER_HOME' -Value $flutterHome
    }
    elseif ($IsLinux) {
        Write-Host 'Installing Flutter on Linux...'
        sudo snap install flutter --classic

        flutter config --enable-linux-desktop
        flutter precache
        export FLUTTER_HOME=/snap/flutter/current/usr/share/flutter
        export PATH=$PATH:$FLUTTER_HOME/bin:$FLUTTER_HOME/bin/cache/dart-sdk/bin
    }
}

function Install-AndroidSDK {
    if ($IsWindows) {
        Write-Host 'Installing Android SDK on Windows...'
        Install-Package 'androidstudio'

        $androidSdkRoot = 'C:\Program Files\Android\Android Studio\SDK\'
        Set-EnvironmentVariable -Name 'ANDROID_SDK_ROOT' -Value $androidSdkRoot
    }
    elseif ($IsLinux) {
        Write-Host 'Installing Android SDK on Linux...'
        sudo snap install android-sdk --classic

        export ANDROID_SDK_ROOT=/snap/android-sdk/current
        export PATH=$PATH:$ANDROID_SDK_ROOT/tools:$ANDROID_SDK_ROOT/platform-tools
    }
}

function Install-BuildTools {
    if ($IsWindows) {
        Write-Host 'Installing C++ Build Tools on Windows...'
        Install-Package 'microsoft-build-tools' 'visualstudio2019-workload-vctools'
    }
    elseif ($IsLinux) {
        Write-selectBox 'Installing C++ Build Tools on Linux...'
        sudo apt-get install build-essential -y
    }
}

function Install-Chrome {
    if ($IsWindows) {
        Write-Host 'Installing Chrome on Windows...'
        Install-Package 'googlechrome'
    }
    elseif ($IsLinux) {
        Write-Host 'Installing Chrome on Linux...'
        sudo snap install google-chrome --classic
    }
}

# Check OS and initialize
if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
    Write-Host 'Detected Windows OS'
    $IsWindows = $true
    $IsLinux = $false
}
else {
    Write-Host 'Detected Linux OS'
    $IsWindows = $false
    $IsLinux = $true
}

# Install Chocolatey if not already installed
Install-Chocolatey

# Update Chocolatey
choco upgrade chocolatey

# Install common packages
$commonPackages = @('git', 'openjdk11', 'python', 'visualstudiocode')
Install-Package $commonPackages

# Install Python packages
python -m pip install --upgrade pip wheel

# Install Flutter and Dart SDK
Install-Flutter

# Install Android SDK
Install-AndroidSDK

# Install C++ Build Tools
Install-BuildTools

# Install Chrome
Install-Chrome

# Check Flutter setup and fix issues
Check-FlutterDoctor

# Final message
Write-Host 'Flutter multi-platform development environment setup complete!'
