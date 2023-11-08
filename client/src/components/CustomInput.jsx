import React from 'react';
import styles from '../styles';

const stringRegex = /^[A-Za-z0-9]+$/;
//const floatRegex = /^(\d*[.])?\d+$/;
//const floatRegex = /^[0-9]+\.[0-9]+$/;
//const floatRegex = /^[(\d+)(.)(\d+)]+$/;
const floatRegex = /^[(\d*\.)?\d+]+$/;


const CustomInput = ({label, value, disabled, type, placeholder, handleValueChange}) => {
    
    const handleValueCheck = (e) => {
        switch (type) {
            case "string":
                return stringRegex.test(e.target.value);
            case "float":
                return floatRegex.test(e.target.value);
        }
    }

    return (
        <>
            {label?
            <label
                htmlFor='name'
                className={styles.label}
            >
                {label}
            </label>
            : null}
            
            <input
                type='text'
                placeholder={placeholder}
                value={value}
                disabled={disabled}
                onChange={(e) => {
                    if (e.target.value==='' || handleValueCheck(e)) handleValueChange(e.target.value)
                }}
                className={styles.input}
            />
        </>
    )
}

export default CustomInput