@echo off
call "C:\Program Files (x86)\Microsoft Visual Studio\2019\Community\VC\Auxiliary\Build\vcvarsall.bat" x64
cls

set "SHADERC=%~dp0\lib\shaderc.exe"
set "FLATC=%~dp0\lib\flatc.exe"
set "LIBS= bgfx.lib bx.lib bimg.lib shell32.lib opengl32.lib user32.lib gdi32.lib winmm.lib enet.lib ws2_32.lib imgui.lib advapi32.lib spdlog.lib"

:main
  :: call :compile_schemas data\schemas data\gen\
  call :compile_project

  echo [End of Build]
goto :eof

:compile_project
  setlocal enabledelayedexpansion
  for /R ./ %%f in (*.program.cpp) do (
    set B=%%f
    set C=%%~nf
    set D=!B:%CD%\=!
    set E=!C:~0,-8!
    if /I not "!C:~0,1!"=="." (
      call :clear_folders !E!
      echo !B:%CD%\=! >> .vscode\bin\!E!.cache
      call :add_folder !E! ./
      call :compile_program !E!
    )
  )

  endlocal
goto :eof


:clear_folders
 if not exist .vscode\bin\ (
  mkdir .vscode\bin\
 )

 if not exist .vscode\obj\ (
  mkdir .vscode\obj\
 )

 if exist .vscode\bin\%1.cache (
  del .vscode\bin\%1.cache
 )

goto :eof


:add_folder
  setlocal enabledelayedexpansion
  set SEARCH_STR=.
  for /R %2 %%f in (*.cpp,*.c) do (
    set B=%%f
    set C=!B:%CD%\=!
    if /I not "!C:~0,1!"=="." (
      if /I not "!C:~-12!"==".program.cpp" (
        echo !B:%CD%\=! >> .vscode\bin\%1.cache
      )
    )
  )

  endlocal
goto :eof


:: (%1 configuration)
:compile_program

 echo [Build] Compiling %1
 
 if not exist .vscode\obj\%1\ (
  mkdir .vscode\obj\%1\
 )

 :: Release via Static with debug info
 cl @.vscode/bin/%1.cache^
 /I ./^
 /I .vscode/include/^
 /I .vscode/include/SDL^
 /I .vscode/include/imgui^
 /MD /Os /Oi /GL /Gy /JMC /FS /Zi /nologo /EHsc /std:c++latest^
 /Fe.vscode/bin/%1^
 /Fo.vscode/obj/%1/^
 /Fd.vscode/bin/%1^
 /link /DEBUG:FULL /SUBSYSTEM:CONSOLE /ENTRY:mainCRTStartup^
 /LIBPATH:.vscode/lib/^
 %LIBS%

 echo Finished compilation.
goto :eof


:compile_schema
  setlocal enabledelayedexpansion
  echo [Build] Building schemas
  for /R %1 %%f in (*.fbs) do (
    set B=%%f
    echo !B:%CD%\=!
    call %FLATC% -c -o %2 -I %1 --gen-mutable --gen-object-api --gen-compare --scoped-enums --grpc !B:%CD%\=!
  )

goto :eof

:compile_all

 
goto :eof


:compile_shaders
  setlocal enabledelayedexpansion
  
  if not exist gen ( 
      mkdir gen 
  )

  if [%1]==[opengl] (
    set "BGFX_PROFILE_VS=--type vertex --platform windows --profile 120"
    set "BGFX_PROFILE_FS=--type fragment --platform windows --profile 120"
    set "BGFX_PROFILE_CS=--type compute --platform windows --profile 430"
  )

  if [%1]==[vulkan] (  
    set "BGFX_PROFILE_VS=--type vertex --platform linux --profile spirv"
    set "BGFX_PROFILE_FS=--type fragment --platform linux --profile spirv"
    set "BGFX_PROFILE_CS=--type compute --platform linux --profile spirv"
  )

  if [%1]==[dx9] (  
    set "BGFX_PROFILE_VS=--type vertex --platform windows --profile vs_3_0 -O 3"
    set "BGFX_PROFILE_FS=--type fragment --platform windows --profile ps_3_0 -O 3"
    set "BGFX_PROFILE_CS=--type compute --platform windows --profile cs_5_0 -O 3"
  )

  if [%1]==[dx11] (  
    set "BGFX_PROFILE_VS=--type vertex --platform windows --profile vs_5_0 -O 3"
    set "BGFX_PROFILE_FS=--type fragment --platform windows --profile ps_5_0 -O 3"
    set "BGFX_PROFILE_CS=--type compute --platform windows --profile cs_5_0 -O 3"
  )

  if [%1]==[dx12] (  
    set "BGFX_PROFILE_VS=--type vertex --platform windows --profile vs_5_0 -O 3"
    set "BGFX_PROFILE_FS=--type fragment --platform windows --profile ps_5_0 -O 3"
    set "BGFX_PROFILE_CS=--type compute --platform windows --profile cs_5_0 -O 3"
  )

  if [%1]==[metal] (  
    set "BGFX_PROFILE_VS=--type vertex --platform osx --profile metal"
    set "BGFX_PROFILE_FS=--type fragment --platform osx --profile metal"
    set "BGFX_PROFILE_CS=--type compute --platform osx --profile metal"
  )

  if [%1]==[pssl] (  
    set "BGFX_PROFILE_VS=--type vertex --platform orbis --profile pssl"
    set "BGFX_PROFILE_FS=--type fragment --platform orbis --profile pssl"
    set "BGFX_PROFILE_CS=--type compute --platform orbis --profile pssl"
  )

  if [%1]==[android] (  
    set "BGFX_PROFILE_VS=--type vertex --platform android"
    set "BGFX_PROFILE_FS=--type fragment --platform android"
    set "BGFX_PROFILE_CS=--type compute --platform android"
  )

  if [%1]==[nacl] (  
    set "BGFX_PROFILE_VS=--type vertex --platform nacl"
    set "BGFX_PROFILE_FS=--type fragment --platform nacl"
    set "BGFX_PROFILE_CS=--type compute --platform android"
  )
  

  for /R .\ %%f in (*.vs) do (
    set B=%%f
    call %SHADERC% -f !B:%CD%\=! -o gen\%%~nxf.%1 %BGFX_PROFILE_VS% --bin2c
  )

  for /R .\ %%f in (*.fs) do (
    set B=%%f
    call %SHADERC% -f !B:%CD%\=! -o gen\%%~nxf.%1 %BGFX_PROFILE_FS% --bin2c
  )

  for /R .\ %%f in (*.ps) do (
    set B=%%f
    call %SHADERC% -f !B:%CD%\=! -o gen\%%~nxf.%1 %BGFX_PROFILE_CS% --bin2c
  )

goto :eof 