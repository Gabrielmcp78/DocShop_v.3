// CLI Guide: Xcode Project Configuration for DocShopAPI

// This guide explains how to configure and build your DocShopAPI command-line tool from the command-line, instead of using Xcode’s graphical interface.

/*

1. Building and Running an Xcode Target from the CLI

Use the `xcodebuild` command:

# Build the target
xcodebuild -scheme DocShopAPI -sdk macosx build

# Run the built executable (example path, adjust if needed)
./build/Debug/DocShopAPI

If you use SwiftPM (Swift Package Manager):

swift build
swift run DocShopAPI

2. Modifying Build Settings from the CLI

You can edit your `.xcodeproj/project.pbxproj` file in a text editor, or use CLI tools like `plutil`. To add a linker flag:

- Open `.xcodeproj/project.pbxproj` in a text editor.
- Search for `OTHER_LDFLAGS` and add:
  -Xlinker -no_warn_no_main

Or use `plutil` (with caution):

plutil -replace "OTHER_LDFLAGS" -string "-Xlinker -no_warn_no_main" path/to/project.pbxproj

3. Editing Info.plist from the CLI

To inspect or modify keys in `Info.plist`:

# Read keys
plutil -p path/to/Info.plist

# Set a key
plutil -replace CFBundleExecutable -string DocShopAPI path/to/Info.plist

Most command-line Swift tools require only the minimal Info.plist.

4. Verifying @main Usage

Ensure your entry-point file (like `APIServer.swift`) uses `@main`. To check:

grep -rn "@main" .

5. General Tips

- All commands work in VSCode’s integrated terminal.
- If you get linker errors about missing `main`, check/add the linker flag.
- For advanced project scripting, look into Tuist (https://tuist.io/) or xcodegen (https://github.com/yonaskolb/XcodeGen).

Summary of Common Commands

# Build & run
xcodebuild -scheme DocShopAPI build
./build/Debug/DocShopAPI

# Add linker flag (edit project.pbxproj manually or with a CLI tool)
# Verify @main presence
grep -rn "@main" .

Let me know if you need specific automation scripts or further help!

*/
