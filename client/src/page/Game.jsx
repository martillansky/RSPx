import React, { useEffect, useRef, useState } from 'react'
import { CustomButton, CustomInput, CustomTabs, GameLoad, MoveSelection, PageHOC } from '../components';
import { useGlobalContext } from '../context';
import styles from '../styles';
import { ethers } from 'ethers';


const Game = () => {
    const {handler, walletAddress, gameData, gamesList, gameIndex, setErrorMessage} = useGlobalContext();
    const [stake, setStake] = useState('');
    const [weapon, setWeapon] = useState('');
    const [disabled, setDisabled] = useState(true);
    const [disabledReveal, setDisabledReveal] = useState(false);

    const [isP2Move, setIsP2Moves] = useState(true);
    const [player1, setPlayer1] = useState(null);
    const [player2, setPlayer2] = useState(null);
    
    
    const [waitGame, setWaitGame] = useState(false);
    const [gameLoadTitle, setGameLoadTitle] = useState(false);

    const [canAskTimeout, setCanAskTimeout] = useState(false);
        
    const gameName = useRef(null);

    const handleClick = async () => {
        setDisabled(true);
        await handler.play(weapon, gameName.current, {
            value: ethers.utils.parseEther(stake),
            //gasLimit: 200000
        })
        .then(() => {
            setCanAskTimeout(false);
            setWaitGame(true);
        })
        .catch((e) => {
            setErrorMessage(e);
        });
    }

    const handleClickReveal = async () => {
        const accessObject = JSON.parse(localStorage.getItem(gameName.current));
        setDisabledReveal(true);
        await handler.solve(gameName.current, accessObject['_c1'], accessObject['_salt'])
        .then(() => {

        })
        .catch (e => {
            setErrorMessage(e);
        })
    }

    const timeoutHandler = async () => {
        if (walletAddress.toLowerCase() === player1.toLowerCase()) {
            await handler.j2Timeout(gameName.current)
            .then(() => {

            })
            .catch (e => {
                setErrorMessage(e);
            })
        } else if (walletAddress.toLowerCase() === player2.toLowerCase()) {
            await handler.j1Timeout(gameName.current)
            .then(() => {

            })
            .catch (e => {
                setErrorMessage(e);
            })
        }
    }

    useEffect(() => {
        const checkTimeout = async () => {
            await handler.getGameTimeData(gameName.current)
            .then((responsedTuple) => {
                const lastAction = Number(responsedTuple[0]);
                const timeout = Number(responsedTuple[1]);

                const now = new Date();
                const mseconds = now.getTime();
                const seconds = Math.floor(mseconds / 1000);

                const secondsSinceLastAction = (seconds-lastAction);

                setCanAskTimeout(secondsSinceLastAction>timeout);
            })
            .catch((e) => {
                setErrorMessage(e);
            })
        }
        if (!!gameName.current) checkTimeout();
    }, [gameName.current]);

    useEffect(() => {
        const getInitialData = async () => {
            try{
                gameName.current = gamesList[gameIndex];

                const tupleGameData = await handler.getGameData(gameName.current); //returns (string memory, address, string memory, address, bool)

                const p1 = tupleGameData[1];
                setPlayer1(p1);
                const p2 = tupleGameData[3];
                setPlayer2(p2);
                const p1Name = tupleGameData[0];
                const p2Name = tupleGameData[2];
                gameData['players'] = [
                    {pName: p1Name, pAddress: p1}, 
                    {pName: p2Name, pAddress: p2}, 
                ];

                const isIncompleteLocal = tupleGameData[4];
                if (walletAddress.toLowerCase() === p1.toLowerCase()) {
                    setIsP2Moves(false);
                    setGameLoadTitle({line1: 'Waiting for second player', line2: 'to stake and select her move...', subtitle: `While you're waiting, you can change to other pending games`});
                    setWaitGame(isIncompleteLocal); // I am the challenger and the second player still did not play if isIncomplete
                } else if (walletAddress.toLowerCase() === p2.toLowerCase()) {
                    var p1Staked = await handler.getGameStake(gameName.current);
                    p1Staked = ethers.utils.formatEther(p1Staked);
                    setStake(p1Staked);
                    setIsP2Moves(true);
                    setGameLoadTitle({line1: 'Waiting for the challenger', line2: 'to reveal her move...', subtitle: `While you're waiting, you can change to other pending games`});
                    setWaitGame(!isIncompleteLocal); // I am the second player and need to wait for first player to reveal his move if !isIncomplete
                }
            } catch (e) {
                setErrorMessage(e);
            }
        }
        if (gameIndex !== null) getInitialData();
    }, []);
    

    useEffect(() => {
        setDisabled(
            !(
                weapon>0
            )
        )
    }, [stake, weapon]);
    

    const renderWeapon = () => {
        return (
            <MoveSelection 
                selectionCB={weapon}
                setSelectionCB = {setWeapon}
            />
        )
    }

    const renderStake = () => {
        return (
            <label
                htmlFor='name'
                className={styles.label}
            >
                Challenger staked: {stake}
            </label>
        )
    }
    const renderP1Reveals = () => {
        return (
            <CustomButton 
                title = "Reveal yor move"
                restStyles = "mt-6"
                handleClick = {handleClickReveal}
                disabled = {disabledReveal}
            />
        )
    }

    const renderP2Moves = () => {
        return (
            <div className='flex flex-col mb-5'>
                <CustomTabs contents={{
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
        )
    }

    return (
        gameIndex === null? null
        :
            <>
                {waitGame && <GameLoad title={gameLoadTitle} timeoutDisabled = {!canAskTimeout} timeoutHandler={timeoutHandler}/>}

                <div className='flex flex-col mb-5'>
                    <label
                        htmlFor='name'
                        className={styles.label}
                    >
                        {gameName.current}
                    </label>
                    {isP2Move? renderP2Moves()
                    :renderP1Reveals()
                    }
                    
                </div>
            </>
    )
}

export default PageHOC(
    Game,
    <>RPSx game</>
);