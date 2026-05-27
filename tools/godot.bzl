"""Repository rule to download a hermetic Godot editor binary."""

_GODOT_VERSION = "4.3-stable"

_GODOT_URLS = {
    "macos": {
        "url": "https://github.com/godotengine/godot/releases/download/{version}/Godot_v{version}_macos.universal.zip",
        "binary_path": "Godot.app/Contents/MacOS/Godot",
    },
    "linux_x86_64": {
        "url": "https://github.com/godotengine/godot/releases/download/{version}/Godot_v{version}_linux.x86_64.zip",
        "binary_path": "Godot_v{version}_linux.x86_64",
    },
    "linux_arm64": {
        "url": "https://github.com/godotengine/godot/releases/download/{version}/Godot_v{version}_linux.arm64.zip",
        "binary_path": "Godot_v{version}_linux.arm64",
    },
    "windows_x86_64": {
        "url": "https://github.com/godotengine/godot/releases/download/{version}/Godot_v{version}_win64.exe.zip",
        "binary_path": "Godot_v{version}_win64.exe",
    },
    "windows_arm64": {
        "url": "https://github.com/godotengine/godot/releases/download/{version}/Godot_v{version}_windows_arm64.exe.zip",
        "binary_path": "Godot_v{version}_windows_arm64.exe",
    },
}

def _get_platform(repository_ctx):
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch

    if "mac" in os_name or "darwin" in os_name:
        return "macos"
    elif "linux" in os_name:
        if arch == "aarch64" or arch == "arm64":
            return "linux_arm64"
        else:
            return "linux_x86_64"
    elif "windows" in os_name or "win" in os_name:
        if arch == "aarch64" or arch == "arm64":
            return "windows_arm64"
        else:
            return "windows_x86_64"
    else:
        fail("Unsupported OS: {}".format(os_name))

def _godot_repository_impl(repository_ctx):
    version = repository_ctx.attr.version
    platform = _get_platform(repository_ctx)
    platform_info = _GODOT_URLS[platform]

    url = platform_info["url"].format(version = version)
    binary_path = platform_info["binary_path"].format(version = version)

    repository_ctx.download_and_extract(
        url = url,
        output = "godot_extracted",
        type = "zip",
    )

    # Ensure the binary is executable (zip extraction does not preserve +x on all platforms)
    repository_ctx.execute(["chmod", "+x", "godot_extracted/" + binary_path])

    # Write the binary path to a file so the run script can find it
    repository_ctx.file(
        "godot_bin_path.txt",
        content = binary_path,
    )

    repository_ctx.file(
        "BUILD.bazel",
        content = """
exports_files(["godot_bin_path.txt"])

filegroup(
    name = "godot_files",
    srcs = glob(["godot_extracted/**"]),
    visibility = ["//visibility:public"],
)
""",
    )

godot_repository = repository_rule(
    implementation = _godot_repository_impl,
    attrs = {
        "version": attr.string(default = _GODOT_VERSION),
    },
)

def _godot_extension_impl(_module_ctx):
    godot_repository(name = "godot")

godot = module_extension(
    implementation = _godot_extension_impl,
)
