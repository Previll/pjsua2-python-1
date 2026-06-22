$ErrorActionPreference = "Stop"

if (-not $env:PJPROJECT_VERSION) { $env:PJPROJECT_VERSION = "2.17" }
if (-not $env:MAX_CALLS) { $env:MAX_CALLS = "512" }

# Download pjproject
Invoke-WebRequest `
  -Uri "https://github.com/pjsip/pjproject/archive/refs/tags/$env:PJPROJECT_VERSION.zip" `
  -OutFile "pj.zip"

Expand-Archive pj.zip -DestinationPath .
Rename-Item "pjproject-$env:PJPROJECT_VERSION" "pjproject"

Set-Location "pjproject"

# Generate Visual Studio solution (assuming Python + VS Build Tools installed)
python ..\scripts\win32\configure.py

# Build Release x64
msbuild /p:Configuration=Release /p:Platform=x64 pjproject.sln

# Build SWIG Python bindings
Set-Location "pjsip-apps\src\swig"
swig -c++ -python pjsua2.i

Set-Location "python"
python setup.py build_ext --inplace

# Copy .pyd into package
Set-Location "..\..\..\..\.."
New-Item -ItemType Directory -Path "src\pjsua2_python" -Force | Out-Null
Copy-Item "pjproject\pjsip-apps\src\swig\python\*.pyd" "src\pjsua2_python\"
