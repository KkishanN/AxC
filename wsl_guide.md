# How to Use Windows Subsystem for Linux (WSL)

This is a comprehensive set of instructions for using your installed Ubuntu WSL environment.

## 1. Starting WSL
- **Quickest Method:** Open Command Prompt or PowerShell, type `wsl`, and press **Enter**.
- **Windows Terminal (Recommended):** Open Windows Terminal, click the dropdown arrow `v` next to the new tab button, and select **Ubuntu-24.04**.
- **Exiting:** Type `exit` and press Enter to leave the Linux environment and return to Windows.

## 2. Managing the Ubuntu System
Because WSL runs a full Linux environment, you should manage it just like a regular Linux machine.

### Updating Packages
It is good practice to keep your system packages up to date. Run these commands regularly:
```bash
sudo apt update
sudo apt upgrade -y
```

### Installing New Software
To install software, use the `apt` package manager. For example, to install `git` or `python3`:
```bash
sudo apt install git python3
```

## 3. Navigating Files
WSL allows seamless file sharing between Windows and Linux.

### Accessing Windows Files from Linux
Your Windows drives are automatically mounted in the `/mnt/` directory in WSL.
- To access your `C:` drive:
  ```bash
  cd /mnt/c
  ```
- To list your Windows User files:
  ```bash
  ls /mnt/c/Users/Kishan/
  ```

### Accessing Linux Files from Windows
You can easily view and edit your Linux files from Windows File Explorer.
1. Open Windows **File Explorer**.
2. Type `\\wsl$` in the address bar and press **Enter**.
3. You will see a folder named **Ubuntu-24.04**. You can browse your entire Linux filesystem here.

## 4. Visual Studio Code Integration
The best way to edit code in WSL is using VS Code.
1. Install **Visual Studio Code** on Windows.
2. Install the **"WSL" extension** in VS Code.
3. Open your WSL terminal (type `wsl` in PowerShell).
4. Navigate to the folder you want to edit.
5. Type `code .` and press Enter. This will open VS Code connected directly to your Linux environment.

## 5. Basic Administrative Commands (Run in PowerShell)
- **Restart WSL:** `wsl --shutdown` (This shuts it down; typing `wsl` again starts it fresh).
- **Check Status:** `wsl --status`
- **List Versions:** `wsl -l -v`
