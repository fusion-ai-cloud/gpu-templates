#!/bin/bash
set -e

echo "Initializing container..."

# Configure SSH for authorized keys
if [ ! -z "$PUBLIC_KEY" ]; then
    echo "Setting up SSH with provided public key..."
    mkdir -p /root/.ssh
    echo "$PUBLIC_KEY" > /root/.ssh/authorized_keys
    chmod 700 /root/.ssh
    chmod 600 /root/.ssh/authorized_keys
    echo "SSH key setup complete."
else
    echo "No SSH public key provided. SSH access will be limited."
fi

# Configure Jupyter password
if [ ! -z "$JUPYTER_PASSWORD" ]; then
    echo "Setting up Jupyter with password authentication..."
    # Generate password hash
    JUPYTER_PASSWORD_HASH=$(python3 -c "from jupyter_server.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
    
    # Update Jupyter config
    mkdir -p /root/.jupyter
    cat > /root/.jupyter/jupyter_notebook_config.py << EOL
c.NotebookApp.password = '$JUPYTER_PASSWORD_HASH'
c.NotebookApp.token = ''
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.allow_root = True
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '/workspace'
EOL
    echo "Jupyter password setup complete."
else
    echo "No Jupyter password provided. Using token authentication."
    # Use default token authentication
    mkdir -p /root/.jupyter
    cat > /root/.jupyter/jupyter_notebook_config.py << EOL
c.NotebookApp.ip = '0.0.0.0'
c.NotebookApp.allow_root = True
c.NotebookApp.open_browser = False
c.NotebookApp.notebook_dir = '/workspace'
EOL
fi

# Configure web console
echo "Setting up web console..."
ttyd -p 7681 bash &
echo "Web console started."

# Start SSH service
echo "Starting SSH service..."
service ssh start
echo "SSH service started."

# Start Jupyter Lab
echo "Starting Jupyter Lab..."
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &
echo "Jupyter Lab started."

echo "Container initialization complete. Services running:"
echo "- SSH: port 22"
echo "- Jupyter Lab: port 8888"
echo "- Web Console: port 7681"

# Keep container running
echo "Container is now running. Use CTRL+C to stop."
tail -f /dev/null
