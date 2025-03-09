#!/usr/bin/env lua
-- build.lua - Automated build script for Maze Runner

-- Define file paths
local SOURCE_FILE = "maze.asm"
local OUTPUT_FILE = "maze.com"
local LOG_FILE = "build.log"

-- Function to check if a command exists
local function command_exists(cmd)
    local handle = io.popen("command -v " .. cmd .. " 2>/dev/null")
    local result = handle:read("*a")
    handle:close()
    return result ~= ""
end

-- Function to run a shell command and return its output and exit status
local function execute_command(cmd)
    print("Executing command: " .. cmd)  -- Debugging line to show the command being executed
    local handle = io.popen(cmd .. " 2>&1; echo $?")
    local output = handle:read("*a")
    handle:close()

    local exit_code = tonumber(output:match("(%d+)$"))
    output = output:gsub("%d+$", "")

    return output, exit_code
end

-- Function to get file size
local function get_file_size(file)
    local handle = io.popen("du -h " .. file .. " | cut -f1")
    local size = handle:read("*a"):gsub("\n", "")
    handle:close()
    return size
end

-- Function to read user input (y/n)
local function get_yes_no()
    local input = io.read(1):lower()
    io.read() -- clear buffer
    return input == "y"
end

-- Color output functions
local function yellow(text) return "\027[1;33m" .. text .. "\027[0m" end
local function green(text) return "\027[0;32m" .. text .. "\027[0m" end
local function red(text) return "\027[0;31m" .. text .. "\027[0m" end

-- Start build process
print(yellow("Starting Maze Runner build process..."))

-- Check if NASM is installed
if not command_exists("nasm") then
    print(red("Error: NASM assembler is not installed."))
    print("Please install NASM first (e.g., 'sudo apt-get install nasm' on Debian/Ubuntu)")
    os.exit(1)
end

-- Assemble the source file
print("Assembling " .. SOURCE_FILE .. " to " .. OUTPUT_FILE .. "...")
local cmd = "nasm -f bin " .. SOURCE_FILE .. " -o " .. OUTPUT_FILE .. " 2> " .. LOG_FILE
local _, exit_code = execute_command(cmd)

-- Check if build was successful
if exit_code == 0 then
    print(green("Build successful!"))
    print("Output file: " .. OUTPUT_FILE .. " (" .. get_file_size(OUTPUT_FILE) .. ")")

    -- Optional: Run in DOSBox if it's installed
    if command_exists("dosbox") then
        print(yellow("Would you like to run the game in DOSBox? (y/n)"))
        if get_yes_no() then
            print("Launching DOSBox...")
            -- Create a temporary DOSBox configuration file
            local conf_file = io.open("dosbox_temp.conf", "w")
            conf_file:write("[autoexec]\n")
            conf_file:write("mount c " .. io.popen("pwd"):read("*l") .. "\n")
            conf_file:write("c:\n")
            conf_file:write(OUTPUT_FILE .. "\n")
            conf_file:close()

            os.execute("dosbox -conf dosbox_temp.conf")
            os.remove("dosbox_temp.conf")
        end
    end
else
    print(red("Build failed!"))
    print("Error log:")
    local log_file = io.open(LOG_FILE, "r")
    if log_file then
        print(log_file:read("*all"))
        log_file:close()
    else
        print("Could not read log file.")
    end
end

-- Optional: Create a distribution package
print(yellow("Would you like to create a distribution package? (y/n)"))
if get_yes_no() then
    local DIST_DIR = "maze_runner_dist"
    os.execute("mkdir -p " .. DIST_DIR)
    os.execute("cp " .. OUTPUT_FILE .. " " .. DIST_DIR .. "/")
    os.execute("cp README.md " .. DIST_DIR .. "/ 2>/dev/null || echo 'README.md not found, skipping...'")

    -- Create a simple batch file to run the game
    local bat_file = io.open(DIST_DIR .. "/run_game.bat", "w")
    bat_file:write("@echo off\n")
    bat_file:write("echo Running Maze Runner...\n")
    bat_file:write(OUTPUT_FILE .. "\n")
    bat_file:close()

    -- Create ZIP archive
    local date = io.popen("date +%Y%m%d"):read("*l")
    local ZIP_FILE = "maze_runner_" .. date .. ".zip"

    if command_exists("zip") then
        os.execute("zip -r " .. ZIP_FILE .. " " .. DIST_DIR)
        print(green("Distribution package created: " .. ZIP_FILE))
    else
        print(yellow("zip command not found. Distribution folder created at: " .. DIST_DIR))
    end
end

print("Build process completed.")

