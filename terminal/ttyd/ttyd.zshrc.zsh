#!/usr/bin/env zsh

# ttyd helper functions for web-based tmux sessions

# Function to spawn a new tmux session accessible via browser
# Usage: tmux_web [session_name] [port]
tmux_web() {
    local session_name="${1:-web_session_$(date +%s)}"
    local port="${2:-8080}"
    
    echo "🌐 Starting web-accessible tmux session: $session_name"
    echo "📡 Port: $port"
    echo "🔗 URL: http://localhost:$port"
    
    # Create or attach to tmux session
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo "📋 Attaching to existing session: $session_name"
        ttyd -p "$port" tmux attach-session -t "$session_name"
    else
        echo "✨ Creating new session: $session_name"
        ttyd -p "$port" tmux new-session -s "$session_name"
    fi
}

# Function to list running ttyd processes
tmux_web_list() {
    echo "🖥️  Active ttyd processes:"
    ps aux | grep "ttyd" | grep -v grep | while read -r line; do
        echo "   $line"
    done
}

# Function to kill ttyd processes using fzf selection
tmux_web_kill() {
    # If a specific port is provided, kill that directly
    if [[ -n "$1" ]]; then
        local port="$1"
        echo "🔪 Killing ttyd process on port $port..."
        
        local pid=$(lsof -ti:$port 2>/dev/null)
        if [[ -n "$pid" ]]; then
            kill "$pid"
            echo "✅ Killed process $pid on port $port"
        else
            echo "❌ No process found on port $port"
        fi
        return
    fi
    
    # No port specified, use fzf to select from running processes
    local processes
    processes=$(ps aux | grep "ttyd" | grep -v grep)
    
    if [[ -z "$processes" ]]; then
        echo "❌ No ttyd processes found"
        return 1
    fi
    
    echo "🔍 Select ttyd process to kill:"
    local selected
    selected=$(echo "$processes" | fzf --height=10 --header="Select ttyd process to kill" --preview-window=hidden)
    
    if [[ -z "$selected" ]]; then
        echo "❌ No process selected"
        return 1
    fi
    
    # Extract PID from the selected line (second column)
    local pid=$(echo "$selected" | awk '{print $2}')
    local port=$(echo "$selected" | grep -o '\-p [0-9]*' | awk '{print $2}')
    
    if [[ -n "$pid" ]]; then
        echo "🔪 Killing ttyd process PID $pid (port $port)..."
        kill "$pid"
        echo "✅ Killed process $pid"
    else
        echo "❌ Could not extract PID from selection"
    fi
}

# Function to open browser to ttyd session using fzf selection
tmux_web_open() {
    # If a specific port is provided, open that directly
    if [[ -n "$1" ]]; then
        local port="$1"
        local url="http://localhost:$port"
        
        echo "🚀 Opening $url in default browser..."
        
        if command -v open >/dev/null; then
            # macOS
            open "$url"
        elif command -v xdg-open >/dev/null; then
            # Linux
            xdg-open "$url"
        else
            echo "❌ Could not detect browser command. Open manually: $url"
        fi
        return
    fi
    
    # No port specified, use fzf to select from running processes
    local processes
    processes=$(ps aux | grep "ttyd" | grep -v grep)
    
    if [[ -z "$processes" ]]; then
        echo "❌ No ttyd processes found"
        return 1
    fi
    
    echo "🔍 Select ttyd process to open in browser:"
    local selected
    selected=$(echo "$processes" | fzf --height=10 --header="Select ttyd process to open" --preview-window=hidden)
    
    if [[ -z "$selected" ]]; then
        echo "❌ No process selected"
        return 1
    fi
    
    # Extract port from the selected line
    local port=$(echo "$selected" | grep -o '\-p [0-9]*' | awk '{print $2}')
    
    if [[ -n "$port" ]]; then
        local url="http://localhost:$port"
        echo "🚀 Opening $url in default browser..."
        
        if command -v open >/dev/null; then
            # macOS
            open "$url"
        elif command -v xdg-open >/dev/null; then
            # Linux
            xdg-open "$url"
        else
            echo "❌ Could not detect browser command. Open manually: $url"
        fi
    else
        echo "❌ Could not extract port from selection"
    fi
}

# Alias for convenience
alias tmweb='tmux_web'
alias tmweb-list='tmux_web_list'
alias tmweb-kill='tmux_web_kill'
alias tmweb-open='tmux_web_open'
