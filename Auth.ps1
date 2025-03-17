# Configuration
$clientId = "xxxxx" # Replace with your client ID
$scopes = "User.Read" # Scopes will be configured within the app registration page for the user.
$redirectUri = "http://localhost:5000" # Use your desired port
$tenantId = "xxxx" #Replace with TenantID
$clientSecret = "xxxxx" #Replace with client secret

# PKCE: gen code
function Generate-PKCE {
    $randomBytes = New-Object byte[] 32
    $randomNumberGenerator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    $randomNumberGenerator.GetBytes($randomBytes)
    $codeVerifier = [Convert]::ToBase64String($randomBytes) -replace '=', '' -replace '\+', '-' -replace '/', '_'
    $codeChallenge = [Convert]::ToBase64String([System.Security.Cryptography.SHA256]::Create().ComputeHash([System.Text.Encoding]::ASCII.GetBytes($codeVerifier))) -replace '=', '' -replace '\+', '-' -replace '/', '_'
    return @{
        CodeVerifier  = $codeVerifier
        CodeChallenge = $codeChallenge
    }
}

$pkce = Generate-PKCE

# Authorization URL builder
$authorizationUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/authorize?" +
    "client_id=$clientId&" +
    "scope=$scopes&" +
    "response_type=code&" +
    "redirect_uri=$([uri]::EscapeDataString($redirectUri))&" +
    "response_mode=query&" +
    "code_challenge=$($pkce.CodeChallenge)&" +
    "code_challenge_method=S256"

# Open the Authorization URL in a Browser
Start-Process $authorizationUrl


#Listen for redirect
$port = 5000
$listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Any, $port)
$listener.Start()
Write-Output "Listening on port $port..."

while ($true) {
    $client = $listener.AcceptTcpClient()
    Write-Output "Connection received from: $($client.Client.RemoteEndPoint)"
    $stream = $client.GetStream()
    $reader = New-Object System.IO.StreamReader($stream)
    $writer = New-Object System.IO.StreamWriter($stream)

    # Read incoming
    $requestLines = @()
    while (($line = $reader.ReadLine()) -ne "") {
        $requestLines += $line
    }

    
    $urlLine = $requestLines | Where-Object { $_ -match "^GET " }
    if ($urlLine) {
        $url = ($urlLine -split " ")[1]
        Write-Output "Requested URL: $url"

        # Extract auth cpde
        if ($url -match "\?code=([^&]+)") {
            $authorizationCode = ($url -split "=")[1] -split "&" | Select-Object -First 1
            Write-Output "Authorization Code: $authorizationCode"

            # Send 200
            $response = "HTTP/1.1 200 OK`r`nContent-Type: text/html`r`n`r`nAuthorization successful! You can close this window."
            $writer.WriteLine($response)
            $writer.Flush()

            #
            $client.Close()
            $listener.Stop()
            break; # Close loop

        } else {
            # Invalid
            $response = "HTTP/1.1 400 Bad Request`r`nContent-Type: text/html`r`n`r`nInvalid request"
            $writer.WriteLine($response)
            $writer.Flush()
            $client.Close()
        }

    } else {
        # Invalid
        $response = "HTTP/1.1 400 Bad Request`r`nContent-Type: text/html`r`n`r`nInvalid request"
        $writer.WriteLine($response)
        $writer.Flush()
        $client.Close()
    }
}


# Token Request
$tokenUrl = "https://login.microsoftonline.com/$tenantId/oauth2/v2.0/token"
$tokenBody = @{
    client_id = $clientId
    client_secret = $clientSecret
    scope = $scopes
    code = $authorizationCode
    redirect_uri = $redirectUri
    grant_type = "authorization_code"
    code_verifier = $pkce.CodeVerifier
}

$tokenResponse = Invoke-RestMethod -Uri $tokenUrl -Method Post -Body $tokenBody

# Extract Access Token
$accessToken = $tokenResponse.access_token

Write-Host "Access Token: $accessToken"

#Prove Auth is as user
$me = "https://graph.microsoft.com/v1.0/me"
Invoke-RestMethod -Uri $me -Method Get -Headers @{Authorization = "Bearer $accessToken"}
