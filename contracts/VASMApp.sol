pragma solidity 0.5.7;
pragma experimental "ABIEncoderV2";

import "./counterfactual/CounterfactualApp.sol";


contract VASMApp {

  uint256 constant MAX_TRANSITIONS = 100;

  struct AppLogic {
    uint256 turnTakerStateIndex;
    uint256 terminalIndex;
    uint256 aliceBalanceIndex;
    uint256 bobBalanceIndex;
    int64[] initialPlaces;
    int64[][MAX_TRANSITIONS] deltas;
  }

  struct AppState {
    address alice;
    address bob;
    int64[] state;
    AppLogic logic;
  }

  struct AppAction {
    uint256 transitionIndex;
    bytes32 transitionHash;
  }

  AppLogic masterLogic;

  constructor(AppLogic memory _masterLogic) public {
    masterLogic = _masterLogic;
  }

  function applyAction(
    bytes calldata encodedState, bytes calldata encodedAction
  )
    external
    view
    returns (bytes memory)
  {
    AppState memory appState = abi.decode(encodedState, (AppState));
    AppAction memory appAction = abi.decode(encodedAction, (AppAction));

    require(
      masterLogic.deltas.length > appAction.transitionIndex,
      "Transition index out of bounds"
    );

    int64[] memory delta = masterLogic.deltas[appAction.transitionIndex];
    AppState memory nextState = appState;

    for (uint256 i = 0; i < delta.length; i++) {
      nextState.state[i] = appState.state[i] + delta[i];
      require(
        nextState.state[i] > -1,
        "Transition cannot be applied to given state."
      );
    }

    return abi.encode(nextState);
  }

  function resolve(bytes calldata encodedState, Transfer.Terms calldata terms)
    external
    pure
    returns (Transfer.Transaction memory)
  {
    AppState memory appState = abi.decode(encodedState, (AppState));
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = uint256(appState.state[uint256(appState.logic.aliceBalanceIndex)]);
    amounts[1] = uint256(appState.state[uint256(appState.logic.bobBalanceIndex)]);

    address[] memory to = new address[](2);
    to[0] = appState.alice;
    to[1] = appState.bob;
    bytes[] memory data = new bytes[](2);

    return Transfer.Transaction(
      terms.assetType,
      terms.token,
      to,
      amounts,
      data
    );
  }

  function isStateTerminal(bytes calldata encodedState)
    external
    view
    returns (bool)
  {
    AppState memory appState = abi.decode(encodedState, (AppState));
    return appState.state[masterLogic.terminalIndex] == 1;
  }

  function getTurnTaker(
    bytes calldata encodedState, address[] calldata signingKeys
  )
    external
    view
    returns (address)
  {
    AppState memory appState = abi.decode(encodedState, (AppState));
    int64 turnTakerState = appState.state[masterLogic.turnTakerStateIndex];

    uint256 turnTakerIndex = uint256(turnTakerState);

    require(
      turnTakerIndex < signingKeys.length, 
      "Turn taker index out of bounds"
    );

    return signingKeys[turnTakerIndex];
  }

}
 