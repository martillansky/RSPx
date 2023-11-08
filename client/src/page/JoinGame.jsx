import React from 'react'
import { CustomButton, PageHOC } from '../components';
import styles from '../styles';
import { useNavigate } from 'react-router-dom';
import { useGlobalContext } from '../context';

const JoinGame = () => {

    const {gamesList, setGameIndex} = useGlobalContext();
    const navigate = useNavigate();
    
    return (
        <>
            <div className='flex flex-col mb-5'>
                <label
                    htmlFor='name'
                    className={styles.label}
                >
                    Resume some game
                </label>
                <div className={styles.joinContainer}>
                    {gamesList.length
                    ? gamesList
                        .map((gameName, index) => (
                        <div key={gameName + index} className={styles.flexBetween}>
                            <p className={styles.joinGameTitle}>{index + 1}. {gameName}</p>
                            <CustomButton
                                title="Join"
                                handleClick={() => {
                                    setGameIndex(index);
                                    navigate(`/game/${gameName}`)
                                }}
                            />
                        </div>
                        )) : (
                        <p className={styles.joinLoading}>Reload the page to see new games</p>
                    )}
                </div>
            </div>
            <p className={styles.infoText} onClick={() => navigate('/start-game')}>
                Or create a new game
            </p>
        </>
    )
}

export default PageHOC(
    JoinGame,
    <>Join a game</>
);