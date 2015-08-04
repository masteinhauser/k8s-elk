function pmt_cmd(){
  REPLY=n
  echo
  echo $1
  echo $ $2
  read -r -p $"[Y/n] "
  if [[ -z "${REPLY// }" ]] || [[ $REPLY =~ ^[Yy]$ ]]
  then
    eval $2
  fi
}

function put_cmd(){
  echo
  echo "$1"
  echo $ $2
  eval $2
}
