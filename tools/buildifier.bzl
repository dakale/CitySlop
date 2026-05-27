"""Repository rule to download the Bazel buildifier binary."""

_BUILDIFIER_VERSION = "v8.5.1"
_BUILDIFIER_URL = "https://github.com/bazelbuild/buildtools/releases/download/{version}/{asset_name}?raw=true"

_BUILDIFIER_ASSETS = {
    "macos_x86_64": "buildifier-darwin-amd64",
    "macos_arm64": "buildifier-darwin-arm64",
    "linux_x86_64": "buildifier-linux-amd64",
    "linux_arm64": "buildifier-linux-arm64",
    "windows_x86_64": "buildifier-windows-amd64.exe",
    "windows_arm64": "buildifier-windows-arm64.exe",
}


def _get_platform(repository_ctx):
    os_name = repository_ctx.os.name.lower()
    arch = repository_ctx.os.arch

    if "mac" in os_name or "darwin" in os_name:
        if arch == "aarch64" or arch == "arm64":
            return "macos_arm64"
        return "macos_x86_64"
    elif "linux" in os_name:
        if arch == "aarch64" or arch == "arm64":
            return "linux_arm64"
        return "linux_x86_64"
    elif "windows" in os_name or "win" in os_name:
        if arch == "aarch64" or arch == "arm64":
            return "windows_arm64"
        return "windows_x86_64"
    else:
        fail("Unsupported OS for buildifier: {}".format(os_name))


def _buildifier_repository_impl(repository_ctx):
    version = repository_ctx.attr.version
    platform = _get_platform(repository_ctx)
    asset_name = _BUILDIFIER_ASSETS[platform]
    url = _BUILDIFIER_URL.format(version = version, asset_name = asset_name)

    repository_ctx.download(
        url = url,
        output = "buildifier_bin",
    )

    if not ("windows" in repository_ctx.os.name.lower() or "win" in repository_ctx.os.name.lower()):
        repository_ctx.execute(["chmod", "+x", "buildifier_bin"])

    repository_ctx.file(
        "BUILD.bazel",
        content = """load(\"@rules_shell//shell:sh_binary.bzl\", \"sh_binary\")

package(default_visibility = [\"//visibility:public\"])

sh_binary(
    name = \"buildifier\",
    srcs = [\"buildifier_bin\"],
)
""",
    )


buildifier_repository = repository_rule(
    implementation = _buildifier_repository_impl,
    attrs = {
        "version": attr.string(default = _BUILDIFIER_VERSION),
    },
)


def _buildifier_extension_impl(module_ctx):
    buildifier_repository(name = "buildifier")


buildifier = module_extension(
    implementation = _buildifier_extension_impl,
)
