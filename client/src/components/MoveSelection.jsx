import React, { useEffect, useState } from 'react'
import styles from '../styles'
import {rock, paper, scissors, spock, lizard} from '../assets';

const MoveSelection = ({selectionCB, setSelectionCB}) => {
    const [selected, setSelected] = useState(selectionCB);
    const handleSelection = (sel) => {
        setSelected(sel); 
        setSelectionCB(sel); 
    }
    
    return (
        <div className="w-full max-w-md px-2 py-2 sm:px-0">
            <label
                        htmlFor='name'
                        className={styles.label}
                    >
                        Select a Weapon
                </label>
        <div className="flex flex-row">
            <img src={rock} alt='rock' className={`${styles.weapon} ${selected===1? 'bg-violet-800': ''}`} onClick={() => {handleSelection(1)}} />
            <img src={paper} alt='paper' className={`${styles.weapon} ${selected===2? 'bg-violet-800': ''}`} onClick={() => {handleSelection(2)}} />
            <img src={scissors} alt='scissors' className={`${styles.weapon} ${selected===3? 'bg-violet-800': ''}`} onClick={() => {handleSelection(3)}} />
            <img src={spock} alt='spock' className={`${styles.weapon} ${selected===4? 'bg-violet-800': ''}`} onClick={() => {handleSelection(4)}} />
            <img src={lizard} alt='lizard' className={`${styles.weapon} ${selected===5? 'bg-violet-800': ''}`} onClick={() => {handleSelection(5)}} />
        </div>
        </div>
    )
}

export default MoveSelection