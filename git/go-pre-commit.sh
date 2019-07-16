#!/bin/bash

echo "Running precommit hooks..."

STAGED_GO_FILES=$(git diff --cached --name-only  -- "*.go")

if [[ "$STAGED_GO_FILES" = "" ]]; then
  exit 0
fi

GOLINT=$GOPATH/bin/golint
GOIMPORTS=$GOPATH/bin/goimports
ERRCHECK=$GOPATH/bin/errcheck

# Check for golint
if [[ ! -x "$GOLINT" ]]; then
  printf "\t\033[41mPlease install golint\033[0m (go get -u golang.org/x/lint/golint)"
  exit 1
fi

# Check for goimports
if [[ ! -x "$GOIMPORTS" ]]; then
  printf "\t\033[41mPlease install goimports\033[0m (go get golang.org/x/tools/cmd/goimports)"
  exit 1
fi

# Check for errcheck
if [[ ! -x "$ERRCHECK" ]]; then
  printf "\t\033[41mPlease install errcheck\033[0m (go get -u github.com/kisielk/errcheck)"
  exit 1
fi

PASS=true

for FILE in $STAGED_GO_FILES
do
  # Run goimports on the staged file to update Go import lines, adding
  # missing ones and removing unreferenced ones. goimports also formats the
  # code in the same style as gofmt
  $GOIMPORTS -w $FILE

  # Run golint on the staged file and check the exit status
  $GOLINT "-set_exit_status" $FILE
  if [[ $? == 1 ]]; then
    printf "\t\033[31mgolint $FILE\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n"
    PASS=false
  else
    printf "\t\033[32mgolint $FILE\033[0m \033[0;30m\033[42mpass\033[0m\n"
  fi

  # Run govet on the staged file and check the exit status
  go vet $FILE
  if [[ $? != 0 ]]; then
    printf "\t\033[31mgo vet $FILE\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n"
    PASS=false
  else
    printf "\t\033[32mgo vet $FILE\033[0m \033[0;30m\033[42mpass\033[0m\n"
  fi

  # Run errcheck on the staged file and check the exit status
  errcheck --ignoretests $FILE
  if [[ $? != 0 ]]; then
    printf "\t\033[31merrcheck $FILE\033[0m \033[0;30m\033[41mFAILURE!\033[0m\n"
    PASS=false
  else
    printf "\t\033[32merrcheck $FILE\033[0m \033[0;30m\033[42mpass\033[0m\n"
  fi

done

if ! $PASS; then
  printf "\033[0;30m\033[41mCOMMIT FAILED\033[0m\n"
  exit 1
else
  printf "\033[0;30m\033[42mCOMMIT SUCCEEDED\033[0m\n"
fi

exit 0
