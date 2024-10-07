# Docker Documentation

## How we Dockerize

As we implement new dependencies and local configurations, we also update Docker. We can create different images for different purposes. For example, we can containerize dependencies for the web app, Android app, and Windows app with indepentend builds. How do we do this? Stay tuned to find out.

At the time of the initial Docker config (10/7), the web app is the only build. The container listens on port 3000. 

## Why we Dockerize

To minimize environment conflicts, we can build tiny virtual machines called containers to run our apps inside of. Docker integrates with our machines to build and run images that our applications are served from. This means that any amount of developers using the same container configuration will have identical environments. When the app is deployed to a remote hosting resource, we can build a container on the hosted machine and run the service in the same environment we built it with.

## Step by Step local configuration

1. Install Docker desktop from [link](https://docs.docker.com/desktop/install/windows-install/ "here"). This is easiest to do via the installer.exe. Make sure to select the x86.
2. Follow the installation instructions on the Docker page above. Please pay special attention to the WSL option per step 3 in the Docker instructions.
3. Once you have successfully installed and and run Docker Desktop, pull the most recent version of your development branch into VS Code.
4. Open a terminal in VS Code with 'ctrl + ~' and ensure it opens in "C:\${projectdirectory}\Project-Emerald"
5. Once you are in the project root, run the command 'docker build -it jewel .' and make sure to include the period. 
6. Docker will take a few minutes to build the image, so set it and forget it for about 10 minutes.
7. After you get a successful build output, you must run the container with the following command 'docker run -it -p 3000:3000 jewel'.
8. Once you get the message "lib/main.dart is being served at http://0.0.0.0:3000", open up Chrome and navigate to "http://localhost:3000/". You can then test the application from the web browser during development.