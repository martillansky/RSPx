import React, { useEffect, useState } from 'react'
import { CustomButton, CustomInput, CustomTabs, MoveSelection, PageHOC, PopoverSelector } from '../components';
import { useGlobalContext } from '../context';
import { useNavigate } from 'react-router-dom';
import { ethers } from 'ethers';
import styles from '../styles';

const generateSalt = () => {
    const byteCount = 32; 
    const randomBytes = new Uint8Array(byteCount);
    window.crypto.getRandomValues(randomBytes);

    // Convert the byte array to a big integer string
    let salt = '';
    for (let i = 0; i < randomBytes.length; i++) {
        salt += ('00' + randomBytes[i].toString(16)).slice(-2);
    }
    return BigInt(`0x${salt}`).toString();
}

const StartGame = () => {
    const {handler, gameData, setShowAlert, playersList, myIndex, setErrorMessage} = useGlobalContext();
    const navigate = useNavigate();

    const [playerChallenged, setPlayerChallenged] = useState(-1);
    const [playerChallengedName, setPlayerChallengedName] = useState('');
    
    const [stake, setStake] = useState('');
    const [weapon, setWeapon] = useState(0);
    
    const [disabled, setDisabled] = useState(true);
    
    const handleClick = async () => {
        try {
            const saltVar = generateSalt();
            setDisabled(true);
            await handler.createGame(`${playersList[myIndex].pName} vs. ${playersList[playerChallenged].pName}`, weapon, saltVar, playersList[playerChallenged].pAddress, {
                value: ethers.utils.parseEther(stake),
            })            
            .then(()=>{
                localStorage.setItem('_c1', weapon);
                localStorage.setItem('_salt', saltVar);
                
                setShowAlert({
                    status: true,
                    type: "info",
                    message: "Your move was submited!"
                });
            })
            .catch((err) => {
                if (err.code === 'ACTION_REJECTED' || err.code === 4001) {
                    setShowAlert({
                        status: true,
                        type: "failure",
                        message: "Transaction cancelled"
                    });
                } else {
                    setErrorMessage(err);
                }
            });
        } catch (e) {
            setErrorMessage(e);
        }
    }

    const getOptions = () => {
        const options = [];
        
        if (playersList.length>0) {
            playersList.map((player, index) => {
                options.push({
                    value: index, 
                    label: player.pName,
                    handleClick: (opt) => {setPlayerChallenged(opt); setPlayerChallengedName(playersList[opt].pName)},
                    disabled: index === myIndex
                })
            });
        }

        return options;
    }

    useEffect(() => {
        if (!(gameData?.activeGame)) navigate('/');
    }, [gameData]);

    useEffect(() => {
        setDisabled(
            !(
                playerChallenged>-1 &&
                stake.length>0 &&
                weapon>0
            )
        )
    }, [playerChallenged, stake, weapon]);
    

    const renderWeapon = () => {
        return (
            <MoveSelection 
                selectionCB = {weapon}
                setSelectionCB = {setWeapon}
            />
        )
    }

    const renderStake = () => {
        return (
            <CustomInput 
                type = "float"
                value = {stake}
                placeholder = "Your stake (Sepolia ETHs)"
                handleValueChange = {setStake}
            />
        )
    }

    const renderChallenge = () => {
        return (
            <>
                <div className='flex flex-row mb-5'>
                    <label
                        htmlFor='name'
                        className={styles.label}
                    >
                        Challenge a Player
                    </label>
                    <PopoverSelector label={`\u00a0 `} options = {getOptions()}/>
                </div>
                <CustomInput 
                    type = "string"
                    value = {playerChallengedName}
                    placeholder = "Click popover"
                    disabled = {true}
                />
            </>
        )
    }

    return (
        playersList?.length > 1? (
        <>
            <div className='flex flex-col mb-5'>
                <CustomTabs contents={{
                    Challenge: renderChallenge(),
                    Stake: renderStake(),
                    Weapon: renderWeapon()
                }}/>
                
                <br/>
                <CustomButton 
                    title = "Confirm"
                    restStyles = "mt-6"
                    handleClick = {handleClick}
                    disabled = {disabled}
                />
            </div>
            <p className={styles.infoText} onClick={() => navigate('/join-game')}>
                Or join an ongoing game
            </p>
        </>
        ) : (
            <p className={styles.joinLoading}>No player registered to be challenged. Reload the page</p>
        )
    )
}

export default PageHOC(
    StartGame,
    <>Create a game</>,
);