import React from 'react'
import styles from '../styles'

const CustomRadioGroup = ({name, options}) => {

    const radioOption = (value, label, handleClick, disabled) => {
        return (
            <div className={`${styles.flexBetween} ${styles.btn} hover:bg-siteViolet`} key={value}>
                <input type="radio" id={value} name={name} value={value} className="form-radio bg-siteViolet" onClick={handleClick} disabled = {disabled} />
                <label htmlFor={value} className={`${styles.joinGameTitle}`}>{label}</label>
            </div>
        )
    }

    return (
        <div className={styles.joinContainer}>
            {options.map(option => radioOption(option.value, option.label, option.handleClick, option.disabled))}
        </div>
    )
}

export default CustomRadioGroup