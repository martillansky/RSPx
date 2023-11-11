import React, { useEffect, useState } from 'react';
import { CustomButton, CustomInput, PageHOC } from '../components';
import { useGlobalContext } from '../context';

const Home = () => {
  const {handler, setErrorMessage, setShowAlert} = useGlobalContext();

  const [player, setPlayer] = useState('');
  const [disabled, setDisabled] = useState(true);
  const [loading, setLoading] = useState(false);

  const handleClick = async () => {
    setLoading(true);
    await handler.createPlayer(player, {gasLimit: 2000000})
    .then(() => {
      setShowAlert({
        status: true,
        type: "info",
        message: "Your request was submited. Please wait for the confirmation!"
      });
    })
    .catch ((e) => {
      setLoading(false);
      setErrorMessage(e);
    });
  }

  useEffect(() => {
    setDisabled(
      !(
        player.length>0
      )
    )
  }, [player]);

  
  return (
    <div className='flex flex-col'>
      <CustomInput 
        label = "Player"
        type = "string"
        value = {player}
        placeholder = "Enter your name"
        handleValueChange = {setPlayer}
      />
      <CustomButton 
        title = "Confirm"
        restStyles = "mt-6"
        handleClick = {handleClick}
        disabled = {disabled}
        loading = {loading}
      />
    </div>
  )
};

export default PageHOC(
  Home,
  <>Welcome to RPSx <br/> A Web3 game</>,
  <>Connect to your wallet to start playing</>
);