@echo on
setlocal enabledelayedexpansion

echo Checking dependencies...

where choco > nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Chocolatey not found. Please install chocolatey first.
    echo Visit: https://chocolatey.org/install
    exit /b 1
)
:: Install deps
choco install -y wget cmake python


:: Download and extract OrbbecSDK
echo Downloading OrbbecSDK...
if exist "%ORBBEC_SDK_DIR%.zip" del "%ORBBEC_SDK_DIR%.zip"
if exist "%ORBBEC_SDK_DIR%" rmdir /s /q "%ORBBEC_SDK_DIR%"

wget https://github.com/orbbec/OrbbecSDK_v2/releases/download/%ORBBEC_SDK_VERSION%/%ORBBEC_SDK_DIR%.zip
powershell -command "Expand-Archive -Path '%ORBBEC_SDK_DIR%.zip' -DestinationPath ."

:: Set up Python virtual environment
if not exist "venv\Scripts\activate.bat" (
    echo Creating virtual environment...
    python -m venv venv
)

:: Activate virtual environment and install conan
call venv\Scripts\activate.bat

:: Install conan if not present
pip show conan >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo Installing conan...
    pip install conan
)

:: Setup conan profile
conan profile detect

:: Clone and build C++ SDK
if not exist "tmp_cpp_sdk\viam-cpp-sdk" (
    mkdir tmp_cpp_sdk
    cd tmp_cpp_sdk
    git clone https://github.com/viamrobotics/viam-cpp-sdk.git
    cd viam-cpp-sdk
) else (
    cd tmp_cpp_sdk\viam-cpp-sdk
)

:: Checkout specific version
git checkout releases/v0.16.0

:: Build C++ SDK
conan create . --build=missing -o:a "&:shared=False" -s:a build_type=Release -s:a compiler.cppstd=17

:: Cleanup
cd ..\..
rmdir /s /q tmp_cpp_sdk

echo Setup completed successfully!
endlocal
