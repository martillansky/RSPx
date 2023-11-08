import React from 'react';
import {RPSx} from '../assets';
import styles from '../styles';
import { useGlobalContext } from '../context';
import Alert from './Alert';

const PageHOC = (Component, title, description) => () => {
    const {showAlert} = useGlobalContext();
    return (
        <div className={styles.hocContainer}>
            {showAlert?.status && <Alert type={showAlert.type} message={showAlert.message}/>}
            <div className={styles.hocContentBox}>
                <div className={styles.hocBodyWrapper}>
                    <div className="flex flex-row w-full">
                        <h1 className={`flex ${styles.headText} head-text`}>
                            {title}
                        </h1>
                    </div>
                    <p className={`${styles.normalText} m-10`}>
                        {description}
                    </p>
                    <Component />
                </div>
                <p className={`${styles.footerText}`}>
                    My application to Kleros
                </p>
            </div>
            <div className="flex flex-1 h-screen w-full bg-siteblack">
                <img src={RPSx} alt='RPSx-img' />
            </div>
        </div>
    )
}

export default PageHOC