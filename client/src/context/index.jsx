
import React, { createContext, useContext, useEffect, useState } from 'react';
import { ethers } from 'ethers';
import Web3Modal from 'web3modal';
import { useNavigate } from 'react-router-dom';

import { GetParams } from '../utils/onboard.js';

import { 
  ABI_Handler, 
  HANDLER_CONTRACT_ADDRESS,
} from '../contract';

import { createEventListeners } from './createEventListeners';

const GlobalContext = createContext();

export const GlobalContextProvider = ({ children }) => {
  const [walletAddress, setWalletAddress] = useState('');
  const [handler, setHandler] = useState(null);
  const [provider, setProvider] = useState(null);
  const [showAlert, setShowAlert] = useState({ status: false, type: 'info', message: '' });
  const [gameData, setGameData] = useState({ 
    players: [], 
    activeGame: null 
  });

  const [errorMessage, setErrorMessage] = useState('');
  const [step, setStep] = useState(1);
  const [myIndex, setMyIndex] = useState(null);
  const [playersList, setPlayersList] = useState([]);
  const [gamesList, setGamesList] = useState([]);
  const [gameIndex, setGameIndex] = useState(null);
  const [updateGameData, setUpdateGameData] = useState(0);
  const [eventTriggered, setEventTriggered] = useState(false);

  const navigate = useNavigate();

  
  //* Reset web3 onboarding modal params
  useEffect(() => {
    const resetParams = async () => {
      setStep(-1); 
      const currentStep = await GetParams();

      setStep(currentStep.step);
    };

    resetParams();

    window?.ethereum?.on('chainChanged', () => resetParams());
    window?.ethereum?.on('accountsChanged', () => resetParams());
  }, []);

  

  //* Set the wallet address to the state
  const updateCurrentWalletAddress = async () => {
    const accounts = await window?.ethereum?.request({ method: 'eth_requestAccounts' });    
    if (accounts) setWalletAddress(accounts[0]);
  };

  useEffect(() => {
    updateCurrentWalletAddress();

    window?.ethereum?.on('accountsChanged', updateCurrentWalletAddress);
  }, []);

  //* Set the smart contract and provider to the state
  useEffect(() => {
    const setSmartContractAndProvider = async () => {
      const web3Modal = new Web3Modal();
      const connection = await web3Modal.connect();
      const newProvider = new ethers.providers.Web3Provider(connection);
      const signer = newProvider.getSigner();
      
      const newHandler = new ethers.Contract(HANDLER_CONTRACT_ADDRESS, ABI_Handler, signer);
      
      setProvider(newProvider);
      setHandler(newHandler);
    };

    setSmartContractAndProvider();
  }, []);

  
  //* Activate event listeners for the smart contract
  useEffect(() => {
    if (
      //step === -1 && 
      handler) {
      createEventListeners(
        navigate,
        handler,
        provider,
        walletAddress,
        setShowAlert,
        setUpdateGameData,
        setEventTriggered,
      );
    }
  }, [
    step, 
    handler, updateCurrentWalletAddress
  ]);
 

  
  //* Set the game data to the state
  useEffect(() => {
    const fetchGameData = async () => {
      if (!!handler && !!walletAddress) {
        try {
          const isPlayerRegistered = await handler.isPlayer(walletAddress);
          if (isPlayerRegistered) {
            setGameData({ activeGame: true });
            var index = 0;
            const pList = [];
            let i = 0;
            const max = Number(await handler.playersLen());
            while ( i < max) {
              const tuplePlayer = await handler.getPlayerNumber(i);
              const newPlayer = {pName: tuplePlayer[0], pAddress: tuplePlayer[1]}
              pList.push(newPlayer);
              if (newPlayer.pAddress.toLowerCase() === walletAddress.toLowerCase()) index = i;
              i++;
            }
            setMyIndex(index);
            setPlayersList(pList);

            const gList = await handler.getGamesPlayer();
            setGamesList(gList.filter(gameName => gameName.length > 0));
            
            const playerName = pList[index].pName;
            navigate(`/start-game`);
            if (!eventTriggered) {
              setShowAlert({
                status: true,
                type: "info",
                message: `Welcome back ${playerName}!`
              });
            } else {
              setEventTriggered(false);
            }
          } else {
            navigate(`/`);
            setShowAlert({
              status: true,
              type: "info",
              message: `Welcome!`
            });
          }
        } catch (e) {
          setErrorMessage(e);
        }
      }
    }
    fetchGameData();
  }, [handler, updateGameData])

  
  //* Handle alerts
  useEffect(() => {
    if (showAlert?.status) {
      const timer = setTimeout(() => {
        setShowAlert({ status: false, type: 'info', message: '' });
      }, [10000]);

      return () => clearTimeout(timer);
    }
  }, [showAlert]);

  
  //* Handle error messages
  useEffect(() => {
    if (errorMessage) {
      var parsedErrorMessage = errorMessage?.reason?.slice(`Error: VM Exception while processing transaction: reverted with reason string '`.length).slice(0, -1);
      if (!parsedErrorMessage) parsedErrorMessage = `${errorMessage?.code}: ${errorMessage?.method}`;
      if (!parsedErrorMessage) parsedErrorMessage = errorMessage;
      
      if (parsedErrorMessage) {
        setShowAlert({
          status: true,
          type: 'failure',
          message: parsedErrorMessage,
        });
      }
    }
  }, [errorMessage]);


  return (
    <GlobalContext.Provider
      value={{
        showAlert,
        setShowAlert,
        provider,
        handler,
        walletAddress,
        playersList,
        gamesList,
        gameData, 
        setGameData,
        myIndex,
        gameIndex, 
        setGameIndex,
        setUpdateGameData,
        setEventTriggered,
        updateCurrentWalletAddress,
        errorMessage,
        setErrorMessage,
      }}
    >
      {children}
    </GlobalContext.Provider>
  );
};

export const useGlobalContext = () => useContext(GlobalContext);
