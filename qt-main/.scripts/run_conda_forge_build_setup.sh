# 2 core available on Travis CI OS X workers: https://docs.travis-ci.com/user/ci-environment/#Virtualization-environments
# CPU_COUNT is passed through conda build: https://github.com/conda/conda-build/pull/1149
export CPU_COUNT="${CPU_COUNT:-2}"

export PYTHONUNBUFFERED=1

conda config --env --set show_channel_urls true
conda config --env --set auto_update_conda false
conda config --env --set add_pip_as_python_dependency false
# Otherwise packages that don't explicitly pin openssl in their requirements
# are forced to the newest OpenSSL version, even if their dependencies don't
# support it.
conda config --env --append aggressive_update_packages ca-certificates # add something to make sure the key exists
conda config --env --remove-key aggressive_update_packages
conda config --env --append aggressive_update_packages ca-certificates
conda config --env --append aggressive_update_packages certifi

# Need strict priority for pypy as defaults is not fixed
# but ppl can turn this off
conda config --env --set channel_priority $(cat ./conda-forge.yml | shyaml get-value channel_priority strict || echo strict)

# CONDA_PREFIX might be unset
export CONDA_PREFIX="${CONDA_PREFIX:-$(conda info --json | jq -r .root_prefix)}"

mkdir -p "${CONDA_PREFIX}/etc/conda/activate.d"
echo "export CPU_COUNT='${CPU_COUNT}'"                                    > "${CONDA_PREFIX}/etc/conda/activate.d/conda-forge-ci-setup-activate.sh"
echo "export PYTHONUNBUFFERED='${PYTHONUNBUFFERED}'"                      >> "${CONDA_PREFIX}/etc/conda/activate.d/conda-forge-ci-setup-activate.sh"

if [[ "${OSX_SDK_DIR:-}" == "" ]]; then
  OSX_SDK_DIR="$(xcode-select -p)/Platforms/MacOSX.platform/Developer/SDKs"
  USING_SYSTEM_SDK_DIR=1
fi
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
CI_SUPPORT=$PWD/.ci_support
source ${SCRIPT_DIR}/cross_compile_support.sh
source ${SCRIPT_DIR}/download_osx_sdk.sh

if [[ "$MACOSX_DEPLOYMENT_TARGET" == 10.* && "${USING_SYSTEM_SDK_DIR:-}" == "1" ]]; then
  # set minimum sdk version to our target
  plutil -replace MinimumSDKVersion -string ${MACOSX_SDK_VERSION} $(xcode-select -p)/Platforms/MacOSX.platform/Info.plist
  plutil -replace DTSDKName -string macosx${MACOSX_SDK_VERSION}internal $(xcode-select -p)/Platforms/MacOSX.platform/Info.plist
fi

if [ ! -z "$CONFIG" ]; then
    if [ ! -z "$CI" ]; then
        echo "CI:" >> ${CI_SUPPORT}/${CONFIG}.yaml
        echo "- ${CI}" >> ${CI_SUPPORT}/${CONFIG}.yaml
        echo "" >> ${CI_SUPPORT}/${CONFIG}.yaml
    fi
    cat ${CI_SUPPORT}/${CONFIG}.yaml
fi

conda info
conda config --env --show-sources
conda list --show-channel-urls