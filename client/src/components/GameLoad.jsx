import React from 'react';
import { useNavigate } from 'react-router-dom';

import CustomButton from './CustomButton';
import { useGlobalContext } from '../context';
import { player01, player02 } from '../assets';
import styles from '../styles';

const GameLoad = ({title, timeoutDisabled, timeoutHandler}) => {
  const { gameData } = useGlobalContext();
  const navigate = useNavigate();

  return (
    <div className={`${styles.flexBetween} ${styles.gameLoadContainer}`}>
      {timeoutHandler?
        <div className={styles.gameLoadBtnBox}>
          <CustomButton
            title="Timeout. Ask for stakes"
            handleClick={() => timeoutHandler()}
            restStyles="mt-6"
            disabled={timeoutDisabled}
          />
        </div>
      : null}

      <div className={`flex-1 ${styles.flexCenter} flex-col`}>
        <h1 className={`${styles.headText} text-center`}>
          {title.line1} 
          <br/>
          {title.line2? title.line2: null}
        </h1>
        <p className={styles.gameLoadText}>
          {title.subtitle}
        </p>

        <div className={styles.gameLoadPlayersBox}>
          <div className={`${styles.flexCenter} flex-col`}>
            <img src={player01} className={styles.gameLoadPlayerImg} />
            <p className={styles.gameLoadPlayerText}>
              {gameData.players[0].pName}
            </p>
            <p className={styles.gameLoadPlayerText}>
              {gameData.players[0].pAddress}
            </p>
          </div>

          <h2 className={styles.gameLoadVS}>Vs</h2>

          <div className={`${styles.flexCenter} flex-col`}>
            <img src={player02} className={styles.gameLoadPlayerImg} />
            <p className={styles.gameLoadPlayerText}>
              {gameData.players[1].pName}
            </p>
            <p className={styles.gameLoadPlayerText}>
              {gameData.players[1].pAddress}
            </p>
          </div>
        </div>

        <div className="mt-2">
          <p className={`${styles.infoText} text-center mb-2`}>OR</p>

          <CustomButton
            title="Join other ongoing games"
            handleClick={() => navigate('/join-game')}
          />
        </div>
      </div>
    </div>
  );
};

export default GameLoad;
