export EDITOR=nvim

if [[ $(uname) == "Linux" ]]; then
  export PATH="$PATH:/opt/nvim-linux-x86_64/bin"
fi

function nvim_open() {
  pushd $1
  nvim
  popd
}
