import { ethers } from 'ethers';
import { ABI_Handler } from '../contract';

const AddNewEvent = (eventFilter, provider, cb) => {
  provider.removeListener(eventFilter);

  provider.on(eventFilter, (logs) => {
    const parsedLog = (new ethers.utils.Interface(ABI_Handler)).parseLog(logs);

    cb(parsedLog);
  });
};

export const createEventListeners = ( navigate, contract, provider, walletAddress, setShowAlert, setUpdateGameData, setEventTriggered ) => {
  const NewPlayerEventFilter = contract.filters.NewPlayer();
  AddNewEvent(NewPlayerEventFilter, provider, ({ args }) => {
    if (walletAddress.toLowerCase() === args.owner.toLowerCase()) {
      setShowAlert({
        status: true,
        type: 'success',
        message: `Hello ${args.name}, you are already registered!`,
      });

      setEventTriggered(true);
      setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
    }
  });

  const NewGameEventFilter = contract.filters.NewGame();
  AddNewEvent(NewGameEventFilter, provider, ({ args }) => {
    if (walletAddress.toLowerCase() === args.player1.toLowerCase() || walletAddress.toLowerCase() === args.player2.toLowerCase()) {
      if (walletAddress.toLowerCase() === args.player2.toLowerCase()) {
        setShowAlert({
          status: true,
          type: 'success',
          message: `You have been challenged in game ${args.gameName}!`,
        });
      }

      if (walletAddress.toLowerCase() === args.player1.toLowerCase()) {
        
        if (!!localStorage.getItem('_c1') && localStorage.getItem('_salt')) {
          const gameAccess = {
            '_c1': localStorage.getItem('_c1'),
            '_salt': localStorage.getItem('_salt'),
          };
          localStorage.setItem(args.gameName, JSON.stringify(gameAccess));
          localStorage.removeItem('_c1');
          localStorage.removeItem('_salt');
        }
        
        setShowAlert({
          status: true,
          type: 'success',
          message: `Game ${args.gameName} created. Challenge submited!`,
        });
      }

      setEventTriggered(true);
      setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
      navigate(`/`);
    }
  });

  const SecondPlayerMovedFilter = contract.filters.SecondPlayerMoved();
  AddNewEvent(SecondPlayerMovedFilter, provider, ({ args }) => {
    if (walletAddress.toLowerCase() === args.player1.toLowerCase()) {
      setShowAlert({
        status: true,
        type: 'success',
        message: `Your game ${args.gameName} has been resumed. Please procees to reveal your move!`,
      });
    } else if (walletAddress.toLowerCase() === args.player2.toLowerCase()) {
      setShowAlert({
        status: true,
        type: 'success',
        message: `Your move was registered in game ${args.gameName}!`,
      });
    }
  });

  
  const FirstPlayerRevealedFilter = contract.filters.FirstPlayerRevealed();
  AddNewEvent(FirstPlayerRevealedFilter, provider, ({ args }) => {
    if (walletAddress.toLowerCase() === args.player1.toLowerCase()) {
      localStorage.removeItem(args.gameName);
    }
    
    if (walletAddress.toLowerCase() === args.player1.toLowerCase() || walletAddress.toLowerCase() === args.player2.toLowerCase()) {
      if (walletAddress.toLowerCase() === args.winner.toLowerCase()) {
        setShowAlert({
          status: true,
          type: 'success',
          message: `You won game ${args.gameName}!`,
        });
      } else if (args.player2.toLowerCase() === args.winner.toLowerCase()) {
        setShowAlert({
          status: true,
          type: 'success',
          message: `You lost game ${args.gameName}!`,
        });
      } else {
        setShowAlert({
          status: true,
          type: 'success',
          message: `It's a tie for game ${args.gameName}!`,
        });
      }

      setEventTriggered(true);
      setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
      navigate(`/`);
    }
  });

  const J1TimeoutFilter = contract.filters.J1Timeout();
  AddNewEvent(J1TimeoutFilter, provider, ({ args }) => {
    if (walletAddress.toLowerCase() === args.player1.toLowerCase() || walletAddress.toLowerCase() === args.player2.toLowerCase()) {
      if (walletAddress.toLowerCase() === args.player2.toLowerCase()) {
        setShowAlert({
          status: true,
          type: 'success',
          message: `You won game ${args.gameName} due to timeout!`,
        });
      } else if (walletAddress.toLowerCase() === args.player1.toLowerCase()) {
        localStorage.removeItem(args.gameName);
        setShowAlert({
          status: true,
          type: 'success',
          message: `You've been dismissed. You lost game ${args.gameName}!`,
        });
      }

      setEventTriggered(true);
      setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
      navigate(`/`);
    }
  });

  const J2TimeoutFilter = contract.filters.J2Timeout();
  AddNewEvent(J2TimeoutFilter, provider, ({ args }) => {
    if (walletAddress.toLowerCase() === args.player1.toLowerCase() || walletAddress.toLowerCase() === args.player2.toLowerCase()) {
      if (walletAddress.toLowerCase() === args.player1.toLowerCase()) {
        localStorage.removeItem(args.gameName);
        setShowAlert({
          status: true,
          type: 'success',
          message: `You won game ${args.gameName} due to timeout!`,
        });
      } else if (walletAddress.toLowerCase() === args.player2.toLowerCase()) {
        setShowAlert({
          status: true,
          type: 'success',
          message: `You've been dismissed. You lost game ${args.gameName}!`,
        });
      }

      setEventTriggered(true);
      setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
      navigate(`/`);
    }
  });
};
