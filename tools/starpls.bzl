"""Repository rule to download the starpls binary."""

_STARPLS_VERSION = "v0.1.22"
_STARPLS_URL = "https://github.com/withered-magic/starpls/releases/download/{version}/{asset_name}?raw=true"

_STARPLS_ASSETS = {
    "macos_x86_64": "starpls-darwin-amd64",
    "macos_arm64": "starpls-darwin-arm64",
    "linux_x86_64": "starpls-linux-amd64",
    "linux_arm64": "starpls-linux-arm64",
    "windows_x86_64": "starpls-windows-amd64.exe",
    "windows_arm64": "starpls-windows-arm64.exe",
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


def _starpls_repository_impl(repository_ctx):
    version = repository_ctx.attr.version
    platform = _get_platform(repository_ctx)
    asset_name = _STARPLS_ASSETS[platform]
    url = _STARPLS_URL.format(version = version, asset_name = asset_name)

    repository_ctx.download(
        url = url,
        output = "starpls_bin",
    )

    if not ("windows" in repository_ctx.os.name.lower() or "win" in repository_ctx.os.name.lower()):
        repository_ctx.execute(["chmod", "+x", "starpls_bin"])

    repository_ctx.file(
        "BUILD.bazel",
        content = """load(\"@rules_shell//shell:sh_binary.bzl\", \"sh_binary\")

package(default_visibility = [\"//visibility:public\"])

sh_binary(
    name = \"starpls\",
    srcs = [\"starpls_bin\"],
)
""",
    )


starpls_repository = repository_rule(
    implementation = _starpls_repository_impl,
    attrs = {
        "version": attr.string(default = _STARPLS_VERSION),
    },
)


def _starpls_extension_impl(module_ctx):
    starpls_repository(name = "starpls")


starpls = module_extension(
    implementation = _starpls_extension_impl,
)
