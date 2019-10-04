# Install Docker in Powershell.
Install-Module -Name DockerMSFTProvider -Repository PSGallery -Force
Install-Package -Name Docker -ProviderName DockerMSFTProvider -Verbose
Install-WindowsFeature Containers
Install-WindowsFeature Hyper-V

### Optional restart switch.###
# Restart-Computer -Force

# Create the docker .json file if required.
New-Item -Name daemon.json -ItemType File -Path 'C:\ProgramData\docker\config'

Get-Service Docker

# Proxy settings
[Environment]::SetEnvironmentVariable("HTTP_PROXY", "PROXY:PORT", [EnvironmentVariableTarget]::Machine)
[Environment]::SetEnvironmentVariable("HTTPS_PROXY", "PROXY:PORT", [EnvironmentVariableTarget]::Machine)

# Pull Docker Images.
docker pull microsoft/windowsservercore
docker pull microsoft/nanoserver
docker pull vmware/powerclicore

# Create and manage docker containers with an image pulled.
docker create -t -i microsoft/windowsservercore
docker start 'container ID'
docker stop 'container ID'

# Get all containers.
docker ps -a 

# Get all running containers.
docker ps 

# Lists docker images downloaded to the local repo.
docker images

# Forcefully remove a running docker container.
docker rm -f 'Container ID'

# Enter a container to interact with it. -it flag is interactive then the command you want to run at the end.
docker exec -it 'container ID' powershell/cmd
