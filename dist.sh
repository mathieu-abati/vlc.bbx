#!/bin/bash
set -e

# Include BuildBox API
source buildbox_utils.sh

echo "Starting VLC distribution process..."

# Define paths
DIST_DIR="${BB_TARGET_DIR}/dist"
APPDIR="${DIST_DIR}/VLC.AppDir"

# Cleanup previous dist
rm -rf "${DIST_DIR}"
mkdir -p "${APPDIR}"

# Copy built files from target build directory
echo "Copying built files to AppDir..."
cp -r "${BB_TARGET_BUILD_DIR}"/* "${APPDIR}/"

# Identify all binaries and plugins to check for dependencies
BINARIES=$(find "${APPDIR}/bin" -type f -executable)
PLUGINS=$(find "${APPDIR}/lib/vlc/plugins" -name "*.so")
# Include VLC core private libs
VLC_CORE_LIBS=$(find "${APPDIR}/lib/vlc" -maxdepth 1 -name "*.so*")
LIBS=$(find "${APPDIR}/lib" -maxdepth 1 -name "*.so*")

# Helper to find and copy dependencies
# Only exclude the absolute core system libraries that must come from the host
EXCLUDE_LIBS="libc.so.6|libpthread.so.0|libdl.so.2|libm.so.6|librt.so.1|ld-linux-x86-64.so.2"

echo "Collecting dependencies..."
mkdir -p "${APPDIR}/lib"

gather_deps() {
    local files="$@"
    local new_found_deps=""

    for f in $files; do
        # Get list of dependencies using ldd
        local deps=$(ldd "$f" 2>/dev/null | grep "=> /" | awk '{print $3}' | grep -vE "$EXCLUDE_LIBS" || true)
        for d in $deps; do
            local dep_name=$(basename "$d")
            if [ ! -f "${APPDIR}/lib/$dep_name" ]; then
                # Use cp -L to dereference symlinks and get actual files
                cp -L "$d" "${APPDIR}/lib/"
                new_found_deps="$new_found_deps ${APPDIR}/lib/$dep_name"
            fi
        done
    done

    if [ -n "$new_found_deps" ]; then
        gather_deps $new_found_deps
    fi
}

gather_deps $BINARIES $PLUGINS $VLC_CORE_LIBS $LIBS

# Copy Qt plugins if they exist
QT_PLUGINS_SRC=""
for dir in "/usr/lib/qt/plugins" "/usr/lib/qt5/plugins" "/usr/lib/x86_64-linux-gnu/qt5/plugins"; do
    if [ -d "$dir" ]; then
        QT_PLUGINS_SRC="$dir"
        break
    fi
done

if [ -n "$QT_PLUGINS_SRC" ]; then
    echo "Copying Qt plugins from $QT_PLUGINS_SRC..."
    mkdir -p "${APPDIR}/lib/qt/plugins"
    cp -r "$QT_PLUGINS_SRC"/* "${APPDIR}/lib/qt/plugins/"
    QT_PLUGINS_FILES=$(find "${APPDIR}/lib/qt/plugins" -name "*.so")
    gather_deps $QT_PLUGINS_FILES
fi

# Fix RUNPATH/RPATH using patchelf
echo "Fixing RUNPATH/RPATH for all bundled binaries and libraries..."
ALL_ELFS=$(find "${APPDIR}" -type f -exec file {} + | grep "ELF" | cut -d: -f1)
for elf in $ALL_ELFS; do
    # Remove existing RPATH/RUNPATH to ensure LD_LIBRARY_PATH is respected.
    patchelf --remove-rpath "$elf" 2>/dev/null || true
done

# Create AppRun script
echo "Creating AppRun script..."
cat > "${APPDIR}/AppRun" <<EOF
#!/bin/bash
HERE="\$(dirname "\$(readlink -f "\$0")")"

# We want our bundled libs to always take precedence
export LD_LIBRARY_PATH="\${HERE}/lib:\${HERE}/lib/vlc:\${LD_LIBRARY_PATH}"

# VLC specific paths
export VLC_PLUGIN_PATH="\${HERE}/lib/vlc/plugins"
export VLC_DATA_PATH="\${HERE}/share/vlc"

# Qt specific paths
if [ -d "\${HERE}/lib/qt/plugins" ]; then
    export QT_PLUGIN_PATH="\${HERE}/lib/qt/plugins"
fi

# Use --plugin-path and --no-plugins-cache to ensure VLC finds the plugins in their new location
exec "\${HERE}/bin/vlc" --no-plugins-cache --plugin-path="\${VLC_PLUGIN_PATH}" "\$@"
EOF
chmod +x "${APPDIR}/AppRun"

# Prepare AppImage metadata
echo "Preparing AppImage metadata..."
if [ -f "${APPDIR}/share/applications/vlc.desktop" ]; then
    cp "${APPDIR}/share/applications/vlc.desktop" "${APPDIR}/"
fi
ICON_PATH=$(find "${APPDIR}/share/icons" -name "vlc.png" | sort -V | tail -n 1)
if [ -n "$ICON_PATH" ]; then
    cp "$ICON_PATH" "${APPDIR}/vlc.png"
    ln -sf vlc.png "${APPDIR}/.DirIcon"
fi

# Create standalone archive (tar.gz)
echo "Creating standalone archive..."
tar -czhf "${DIST_DIR}/vlc-standalone-x86_64.tar.gz" -C "${DIST_DIR}" VLC.AppDir

# Create AppImage
APPIMAGETOOL=$(command -v appimagetool-x86_64.AppImage || echo "")
if [ -z "$APPIMAGETOOL" ]; then
    echo "Error: appimagetool not found in PATH."
    exit 1
fi

echo "Creating AppImage using $APPIMAGETOOL..."
export ARCH=x86_64
"$APPIMAGETOOL" --appimage-extract-and-run "${APPDIR}" "${DIST_DIR}/VLC-x86_64.AppImage"

echo "Standalone archive: ${DIST_DIR}/vlc-standalone-x86_64.tar.gz"
echo "AppImage:           ${DIST_DIR}/VLC-x86_64.AppImage"
