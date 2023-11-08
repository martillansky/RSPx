import React from 'react';
import styles from '../styles';
import { AlertIcon } from '../assets';


const CustomButton = ({title, restStyles, handleClick, disabled, loading}) => {
    return (
        <button
            type='button'
            className={`${styles.btn} ${restStyles}`}
            onClick={handleClick}
            disabled={disabled || loading}
        >
            {title} {loading? <AlertIcon /> : null}
        </button>
    )
}

export default CustomButton