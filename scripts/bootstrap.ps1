# Clona (o inicializa vacío) los repositorios backend y frontend dentro de Carpeta_Viva.
$ErrorActionPreference = "Stop"
Set-Location (Join-Path $PSScriptRoot "..")

$vars = @{}
if (Test-Path ".env") {
  Get-Content ".env" | Where-Object { $_ -match "^\s*[^#].*=" } | ForEach-Object {
    $k, $v = $_ -split "=", 2
    $vars[$k.Trim()] = $v.Trim()
  }
}

function Preparar($nombre, $url) {
  if (Test-Path "$nombre/.git") { Write-Host "${nombre}: ya existe" }
  elseif ($url) { git clone $url $nombre }
  else {
    New-Item -ItemType Directory -Force -Path $nombre | Out-Null
    git -C $nombre init -b main
    Write-Host "${nombre}: sin URL en .env, repositorio vacío inicializado"
  }
}

Preparar "backend" $vars["BACKEND_REPO_URL"]
Preparar "frontend" $vars["FRONTEND_REPO_URL"]
if (-not (Test-Path ".env")) { Copy-Item ".env.example" ".env"; Write-Host "Se creó .env: completa los valores antes de levantar los servicios." }
