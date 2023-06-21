#!/bin/bash
set -e

#Make script aware of its location
SCRIPTPATH="$( cd "$(dirname -- "$0")" ; pwd -P )"

source $SCRIPTPATH/config/configs.cfg
source $SCRIPTPATH/config/helper.cfg
source $SCRIPTPATH/config/menu_functions.cfg

case "$1" in
'deploy-aggregator')
  deploy-aggregator
  ;;

'deploy-wrapper')
  deploy-wrapper    
  ;;

'upgrade-wrapper')
  upgrade-wrapper    
  ;;

'deploy-wesdt-swap')
  deploy-wesdt-swap
  ;;

'relayer-stake')
  relayer-stake
  ;;

'burn-tokens')
  burn-tokens
  ;;

'deploy-bridge-contracts')
  echo -e 
  echo "PREREQUIREMENTS: AGGREGATOR & BRIDGED_TOKENS_WRAPPER deployed"
  echo -e 
  deploy-bridge-contracts
  ;;

'create-safe-transaction')
  create-safe-transaction
  ;;

'add-relayer')
  addBoardMember
  ;;

'remove-relayer')
  removeBoardMember
  ;;

'issue-base-token')
  issue-base-token
  ;;

'whitelist-token')
  echo -e 
  echo "PREREQUIREMENTS: BRIDGED_TOKENS_WRAPPER needs to have MINT+BURN role for the UNIVERSAL TOKEN"
  echo "Check and update TOKENS SETTINGS section in configs.cfg"
  source $SCRIPTPATH/config/configs.cfg
  echo -e
  whitelist-token
  ;;

'remove-whitelist-token')
  echo -e 
  echo "PREREQUIREMENTS: BRIDGED_TOKENS_WRAPPER needs to have MINT+BURN role for the UNIVERSAL TOKEN"
  echo "Check and update TOKENS SETTINGS section in configs.cfg"
  source $SCRIPTPATH/config/configs.cfg
  echo -e
  remove-whitelist-token
  ;;

'set-safe-max-tx')
  set-safe-max-tx
  ;;

'set-safe-batch-block-duration')
  set-safe-batch-block-duration
  ;;

'change-quorum')
  change-quorum
  ;;

'pause-contracts')
  pause-contracts
  ;;

'unpause-contracts')
  unpause-contracts
  ;;

'set-swap-fee')
  set-fee
  ;;

'mint-chain-specific')
  mint-chain-specific
  ;;

'mint-universal')
  mint-universal
  ;;

'upgrade-wrapper-universal-token')
  upgrade-wrapper-universal-token   
  ;;

'upgrade-wrapper-chain-specific-token')
  upgrade-wrapper-chain-specific-token  
  ;;

'full-setup')
  full-setup  
  ;;

'add-universal-to-bridge')
  add-universal-to-bridge  
  ;;

*)
  echo "Usage: Invalid choice: '"$1"'" 
  echo -e 
  echo "Choose from:"
  echo "  { \"deploy-aggregator\", \"deploy-wrapper\", \"upgrade-wrapper\", \"deploy-bridge-contracts\", \"add-relayer\", \"remove-relayer\", \"whitelist-token\", "
  echo "    \"remove-whitelist-token\", \"set-safe-max-tx\", \"set-safe-batch-block-duration\", \"change-quorum\", \"pause-contracts\", \"unpause-contracts\", "
  echo "    \"set-swap-fee\", \"mint-chain-specific\", \"upgrade-wrapper-universal-token\", \"upgrade-wrapper-chain-specific-token\" }"
  ;;

esac
