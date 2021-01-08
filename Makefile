PREFIX := $(HOME)
MAKE_PATH := $(dir $(realpath $(firstword $(MAKEFILE_LIST))))
# RELEASE := $(shell lsb_release -cs)
SHELL := /bin/bash

include $(MAKE_PATH).local
OS_NAME := $(shell uname -s | tr A-Z a-z)
ALTERNATE_RELEASE ?= cosmic
OS_DIST ?= $(shell uname)
IOSEVKA_VERSION ?= 4.3.0
DOCKER_MACHINE_VERSION ?= v0.16.0
FEX_VERSION ?= 2.0.0
GIT_USER_NAME ?= Anonymous
GIT_USER_EMAIL ?= anonymous@gmail.com
GIT_USER_SIGNINGKEY ?= A1E2B3BFE2AF174D
VSCODE_EXTENSIONS ?= bungcip.better-toml dasfranck.jellybeans \
		karyfoundation.theme-karyfoundation-themes mauve.terraform pendrica.chef \
		rebornix.ruby rust-lang.rust sidneys1.gitconfig teabyii.ayu ms-vscode.go \
		craigmaslowski.erb ms-vscode.cpptools vscode-icons-team.vscode-icons \
		eamodio.gitlens peterjausovec.vscode-docker sdras.night-owl fisheva.eva-theme

.PHONY: install
install: fonts terminal packages gnome devtools

###############################################################################
### Terminal tools/utilities/shell
###############################################################################
.PHONY: terminal
terminal: zsh vim tmux

.PHONY: zsh
zsh: ## Installs prezto and zsh configs
ifdef SUDO_USER
	apt -y install zsh
else
	ln -snf $(MAKE_PATH)prezto $(PREFIX)/.zprezto
	ln -snf $(MAKE_PATH)prezto/runcoms/zlogout $(PREFIX)/.zlogout
	ln -snf $(MAKE_PATH)prezto/runcoms/zprofile $(PREFIX)/.zprofile
	ln -snf $(MAKE_PATH)prezto/runcoms/zshenv $(PREFIX)/.zshenv
	ln -snf $(MAKE_PATH)zsh/zshrc $(PREFIX)/.zshrc
	ln -snf $(MAKE_PATH)zsh/zlogin $(PREFIX)/.zlogin
	ln -snf $(MAKE_PATH)zsh/zpreztorc $(PREFIX)/.zpreztorc
endif

.PHONY: vim
vim: ## Install vim and friends
ifdef SUDO_USER
	apt -y install vim
else
	ln -snf $(MAKE_PATH)vim $(PREFIX)/.vim
	ln -snf $(MAKE_PATH)vim/vimrc $(PREFIX)/.vimrc
endif

.PHONY: tmux
tmux: ## Install and configure tmux
ifdef SUDO_USER
	apt -y install tmux xsel
else
	ln -snf $(MAKE_PATH)tmux $(PREFIX)/.tmux
	ln -snf $(MAKE_PATH)tmux/tmux.conf $(PREFIX)/.tmux.conf
endif

.PHONY: gpg
gpg:
ifdef SUDO_USER
	apt -y install pinentry-tty pinentry-curses pinentry-gnome3
endif

###############################################################################
### Fonts
###############################################################################
.PHONY: fonts
fonts: ## Installs the iosevka fonts
ifndef SUDO_USER
	mkdir -p $(PREFIX)/.local/share
	ln -snf $(MAKE_PATH)fonts $(PREFIX)/.local/share/fonts
	fc-cache
endif

###############################################################################
### Non specific packages
###############################################################################
.PHONY: packages
packages: snap-packages apt-packages

.PHONY: snap-packages
snap-packages: ## Installs non-specific packages through snap.
ifdef SUDO_USER
	snap install spotify
	snap install slack --classic
endif

.PHONY: apt-packages
apt-packages: ## Install non-specific packages through apt
ifdef SUDO_USER
	apt -y install zeal jq
endif

.PHONY: source
source: ## Temporary spot for building packages from source
# TODO: figure out a better way to handle generic builds
ifdef SUDO_USER
	curl -LSso tmp/fex.tar.gz https://github.com/jordansissel/fex/archive/v$(FEX_VERSION).tar.gz
	tar zxvf tmp/fex.tar.gz -C tmp
	make -C tmp/fex-$(FEX_VERSION) fex
	make -C tmp/fex-$(FEX_VERSION) fex.1
	make -C tmp/fex-$(FEX_VERSION) install
endif

###############################################################################
# Gnome setup
###############################################################################
.PHONY: gnome
gnome: ## Remove ubuntu themed gnome for vanilla and add custom settings
ifdef SUDO_USER
	apt -y remove gnome-shell-extension-ubuntu-dock
	apt -y install gnome-session
	apt -y install gnome-tweak-tool
	# Get rid of wayland and go back to xorg due to incompatibilities.
	install -m 0644 $(MAKE_PATH)gnome/custom.conf /etc/gdm3/custom.conf
	ln -snf /usr/share/xsessions/gnome-xorg.desktop /usr/share/xsessions/gnome.desktop
else
	# Update the settings if we are not running in superuser mode.
	gsettings set org.gnome.desktop.interface gtk-theme Yaru-dark
	gsettings set org.gnome.desktop.interface monospace-font-name 'Iosevka 13'
	gsettings set org.gnome.desktop.peripherals.touchpad click-method fingers
	gsettings set org.gnome.settings-daemon.plugins.color night-light-enabled true
	gsettings set org.gnome.desktop.background show-desktop-icons false
	gsettings set org.gnome.desktop.wm.keybindings switch-windows-backward "['<Shift><Alt><Super>i']"
	gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-up "['<Primary><Alt>i']"
	gsettings set org.gnome.desktop.wm.keybindings switch-to-workspace-down "['<Primary><Alt>k']"
	gsettings set org.gnome.desktop.wm.keybindings switch-windows "['<Alt><Super>i']"
	
	$(MAKE_PATH)gnome/jellybeans-term.sh
endif

###############################################################################
# Development tools
###############################################################################
.PHONY: devtools
devtools: build-deps vscode

.PHONY: git
git:
ifdef SUDO_USER
	apt -y install git
else
	@awk \
		-v name=$(GIT_USER_NAME) \
		-v email=$(GIT_USER_EMAIL) \
		-v key=$(GIT_USER_SIGNING_KEY) \
		-v github=$(GITHUB_USER) \
		'{ \
				gsub("##GIT_USER_NAME##",name); \
				gsub("##GIT_USER_EMAIL##",email); \
				gsub("##GIT_USER_SIGNINGKEY##",key); \
				gsub("##GITHUB_USER##",github); \
				print \
		}' git/.gitconfig > $(MAKE_PATH)tmp/gitconfig
		install $(MAKE_PATH)tmp/gitconfig $(PREFIX)/.gitconfig
endif

.PHONY: build-deps
build-deps: ## Package dependencies
ifdef SUDO_USER
	apt -y install apt-transport-https ca-certificates curl software-properties-common
	apt -y install build-essential
endif

.PHONY: vscode
vscode: ## Installs VSCode
ifdef SUDO_USER
	snap install code --classic
else
	@for ext in $(VSCODE_EXTENSIONS); do \
		code --install-extension $$ext ;\
	done
	ln -snf $(MAKE_PATH)vscode/settings.json $(PREFIX)/.config/Code/User/settings.json
	ln -snf $(MAKE_PATH)vscode/keybindings.json $(PREFIX)/.config/Code/User/keybindings.json
endif

# .PHONY: docker
# docker: ## Installs docker
# ifdef SUDO_USER
# 	curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
# 	install -D $(MAKE_PATH)sources.list.d/docker.$(ALTERNATE_RELEASE).list /etc/apt/sources.list.d
# 	apt-get -y update
# 	apt -y install docker-ce
# 	usermod -a -G docker $(SUDO_USER)
# endif

###############################################################################
### Update targets
###############################################################################
.PHONY: update
update: update-pathogen update-submodules #update-fonts

.PHONY: update-pathogen
update-pathogen: ## Updates the pathogen
	curl -LSso $(MAKE_PATH)vim/autoload/pathogen.vim https://tpo.pe/pathogen.vim

.PHONY: update-submodules
update-submodules: ## Update all the submodules
	git submodule update --init --recursive

# .PHONY: update-fonts
# update-fonts: ## Install custom fonts
# 	mkdir /tmp/iosevka
# 	curl -LSso /tmp/iosevka.zip https://github.com/be5invis/Iosevka/releases/download/v$(IOSEVKA_VERSION)/01-iosevka-$(IOSEVKA_VERSION).zip
# 	unzip /tmp/iosevka.zip -d /tmp/iosevka
# 	rsync -av --delete /tmp/iosevka/ttf/* $(MAKE_PATH)/fonts

###############################################################################
### Clean targets
###############################################################################
.PHONY: clean
clean:
	rm -rf $(MAKE_PATH)tmp/*
