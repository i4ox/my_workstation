# How to install all programming languages needed for DevOps? The right way!

## Rust

```sh
curl --proto '=https' --tlsv1.2 https://sh.rustup.rs -sSf | sh
. "$HOME/.cargo/env"
cargo --version
rustc --version
```

## Python

```sh
git clone https://github.com/pyenv/pyenv.git ~/.pyenv
cd ~/.pyenv && src/configure && make -C src
echo 'export PYENV_ROOT="$HOME/.pyenv"' >> ~/.bashrc
echo '[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(pyenv init -)"' >> ~/.bashrc
pyenv --version

yay -S --needed base-devel openssl zlib xz tk
pyenv install 3.x.x
pyenv global 3.x.x
python --version
```

## NodeJS

```sh
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
nvm install --lts
node --version
npm --version
```

## Java

```sh
curl -s "https://get.sdkman.io" | bash
source "/home/i4ox/.sdkman/bin/sdkman-init.sh"
sdk version
sdk install java 21.0.2-tem
java --version
javac --version
```

## Golang

```sh
git clone https://github.com/go-nv/goenv.git ~/.goenv
echo 'export GOENV_ROOT="$HOME/.goenv"' >> ~/.bashrc
echo 'export PATH="$GOENV_ROOT/bin:$PATH"' >> ~/.bashrc
echo 'eval "$(goenv init -)"' >> ~/.bashrc
echo 'export PATH="$GOROOT/bin:$PATH"' >> ~/.bashrc
echo 'export PATH="$PATH:$GOPATH/bin"' >> ~/.bashrc
goenv install x.x.x
goenv global x.x.x
go version
```

## Ruby

```sh
git clone https://github.com/rbenv/rbenv.git ~/.rbenv
echo 'eval "$(~/.rbenv/bin/rbenv init - bash)"' >> ~/.bashrc
git clone https://github.com/rbenv/ruby-build.git "$(rbenv root)"/plugins/ruby-build
yay -S --needed base-devel rust libffi libyaml openssl zlib
rbenv install x.x.x
rbenv global x.x.x
ruby --version
```
