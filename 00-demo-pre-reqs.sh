#!/bin/bash
# install [direnv](http://direnv.net/)
brew install direnv
# install [gcloud](https://cloud.google.com/sdk/#Quick_Start)
brew cask install google-cloud-sdk
# setup bashrc with includes (.envrc using direnv)
gcloud auth login
