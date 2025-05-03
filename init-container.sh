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
    
    # Debug - print Jupyter version
    jupyter --version
    
    # Generate password hash and print for debugging
    JUPYTER_PASSWORD_HASH=$(python -c "from jupyter_server.auth import passwd; print(passwd('$JUPYTER_PASSWORD'))")
    echo "Generated password hash (debug): $JUPYTER_PASSWORD_HASH"
    
    # Create config directory if it doesn't exist
    mkdir -p /root/.jupyter
    
    # Generate JupyterLab config file
    jupyter lab --generate-config -y
    
    # Configure JupyterLab with password
    cat > /root/.jupyter/jupyter_lab_config.py << EOL
c.ServerApp.password = '$JUPYTER_PASSWORD_HASH'
c.ServerApp.token = ''
c.ServerApp.ip = '0.0.0.0'
c.ServerApp.allow_root = True
c.ServerApp.open_browser = False
c.ServerApp.notebook_dir = '/workspace'
EOL
    
    echo "Jupyter password setup complete."
else
    echo "No Jupyter password provided. Using token authentication."
    # Default token authentication will be used
fi

# Create workspace directory if it doesn't exist
mkdir -p /workspace

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
cd /workspace
jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root &
echo "Jupyter Lab started."

echo "Container initialization complete. Services running:"
echo "- SSH: port 22"
echo "- Jupyter Lab: port 8888"
echo "- Web Console: port 7681"

# Keep container running
echo "Container is now running. Use CTRL+C to stop."
tail -f /dev/null
