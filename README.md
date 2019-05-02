# vasm-cf
Vector Addition State Machine interpreter compatible with [Counterfactual](https://www.counterfactual.com) state channels

## What is this?
A prototype of a simple computing layer that can be run inside state channels. 

## How does it work?
By implementing a [vector addition system with states](https://en.wikipedia.org/wiki/Vector_addition_system), a smart contract can store a state machine as a finite set of integer vectors. In a VASS, the initial state is a single vector of non-negative integers. Each transition is a single vector of integers, both negative and non-negative. To apply a transition and get the next state, we add every element of the current state vector and the firing transition vector. If the resulting vector has any negative values, it is not a valid state.

Here's a [better explanation](https://github.com/bitwrap/bitwrap-io/blob/master/whitepaper.md#vass-state-machine-example) from the [Bitwrap](https://bitwrap.github.io) whitepaper.

The data structure is trivial to implement in Solidity:
```solidity
  uint256 constant MAX_TRANSITIONS = 100;

  struct AppLogic {
    int64[] initialPlaces;
    int64[][MAX_TRANSITIONS] deltas;
  }
```

## Why is this useful?
Storing the state of a Counterfactual application this way makes perofrming transitions simpler and generalized:
```solidity
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
  ```

AND since [vector addition systems are petri-net equivalent](https://www.blahchain.com/posts/firstpost.html#vector-addition-systems-are-petri-net-equivilent), we unlock the potential to _visually_ program our smart contracts using a [Petri Net editor](https://www.blahchain.com/PetriNetEditor/). Processes modelled using Petri nets can be stored in `struct AppLogic` and interpreted on-chain using `function applyAction`.

### Petri what? Visual programming??
  
from [Why Visual Programming Doesn’t Suck](https://blog.statebox.org/why-visual-programming-doesnt-suck-2c1ece2a414e):
>![Petri net animation](https://cdn-images-1.medium.com/max/1600/1*i1sgKaodpQ2owhPRI_nM4A.gif)
> 
>Process for an ATM converting regular money to Bitcoin.

>The diagram above is a simple Petri net. The little black dot traveling around is a “token” which represents the current state of the Petri net. As you can see, this is not just a diagram, it’s one that can capture different states by “firing transitions” (the little rectangles are transitions). The interesting thing is that because Petri nets are well structured, one can compile the diagram above into a lower level language to run as a program which interacts with multiple micro-services and/or modules.

In the article, Anton explains the advantages of visually modeling processes while leveraging the power of diagrammatic reasoning. One of my favorite advantages is that it becomes "easier for non-technical people to contribute to the modelling of the process in a meaningful way." This is much needed in the blockchain space, where the barrier to meaningfully participating in the creation of smart contracts is incredibly high. Removing "having to learn Solidity" from the list of prerequisites would be huge.
For technical folks, Petri nets can lower the barrier to building formally verified contracts. This is what Anton and the rest of the team at [Statebox](https://statebox.org) are working towards with their "formally verified process language [that uses] robust mathematical principles to prevent errors, allow compositionality and ensure termination." A language like that on Ethereum would be super, and hopefully this repo elucidates what running it in state channels might look like.

### Cool. What else is possible?

1. If I can show that VASM can be securely interpreted in state channels, it might be possible to run WASM applications as well using TrueBit's [WebAssembly interpreter](https://github.com/TrueBitFoundation/webasm-solidity)
2. Presently, the VASM logic exists as a state variable in a deployed smart contract and is set via the constructor. Obviously adding a function to switch out the logic creates a simple "upgrade" mechanism, but this idea can be taken a step further by making `AppLogic` a part of the state passed around in the channel. Instead of installing applications through the [Counterfactual protocol](https://specs.counterfactual.com/en/latest/05-install-protocol.html), participants install the VASM interpreter and "load" the application by signing a state update. This opens the dangerous but interesting possibility of "renegotiating" a contract in the middle of its execution by agreeing to modify parts of it's logic. Risk can be mitigated with immutable restrictions on how the logic can be mutated.
3. Petri nets can be used to [construct a Domain Specific Language](https://www.blahchain.com/posts/dsl_creation.html) that is NOT Turing complete. VASM can make it easy to build and run smart contract DSLs that are state channel compatible.

## Does this code work?

No. As of now, the contract compiles (you can try with `yarn && yarn build`) but nothing is tested. This is mostly to share an idea and recieve feedback. Feel free to open an issue :)
  
