import socket
import os

def get_local_ip():
    try:
        # Create a dummy socket to connect to an external server (Google DNS)
        # We don't actually send data, just use it to find the source IP for the route
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        s.connect(("8.8.8.8", 80))
        ip = s.getsockname()[0]
        s.close()
        return ip
    except Exception:
        # Fallback
        return socket.gethostbyname(socket.gethostname())

def update_config_file(new_ip):
    config_path = os.path.join("lib", "config", "app_config.dart")
    
    if not os.path.exists(config_path):
        print(f"Error: Could not find {config_path}")
        return False
        
    try:
        updated_lines = []
        updated = False
        
        with open(config_path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
            
        for line in lines:
            # Safer updating: Modify line only if it matches our variable pattern
            if "static const String _localIp =" in line:
                current_ip_part = line.split('"')[1]
                if current_ip_part == new_ip:
                    print(f"Config is already up to date: {new_ip}")
                    return True
                
                print(f"Updating IP from {current_ip_part} to {new_ip}...")
                new_line = f'  static const String _localIp = "{new_ip}";\n'
                updated_lines.append(new_line)
                updated = True
            else:
                updated_lines.append(line)
        
        if updated:
            with open(config_path, 'w', encoding='utf-8') as f:
                f.writelines(updated_lines)
            return True
        else:
            print("Error: Could not find _localIp variable line in app_config.dart")
            return False
            
    except Exception as e:
        print(f"Error updating file: {e}")
        return False

if __name__ == "__main__":
    print("--- Auto-Update App Config IP ---")
    ip = get_local_ip()
    print(f"Detected Local IP: {ip}")
    if update_config_file(ip):
        print("Successfully updated app_config.dart")
        print("Please restart your Flutter app (Shift+R) for changes to take effect.")
    else:
        print("Update failed.")
        
    input("Press Enter to exit...")
