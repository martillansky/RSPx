import { useState, useEffect } from 'react';
import Modal from 'react-modal';

import styles from '../styles';
import { useGlobalContext } from '../context';
import { GetParams } from '../utils/onboard.js';

const OnboardModal = () => {
  const [modalIsOpen, setIsOpen] = useState(false);
  const { setUpdateGameData } = useGlobalContext();
  const [step, setStep] = useState(-1);
  
  async function resetParams() {
    const currentStep = await GetParams();
    setStep(currentStep.step);
    setIsOpen(currentStep.step !== -1);
    setUpdateGameData((prevUpdateGameData) => prevUpdateGameData + 1);
  }

  useEffect(() => {
    resetParams();

    window?.ethereum?.on('chainChanged', () => {
      resetParams();
    });

    window?.ethereum?.on('accountsChanged', () => {
      resetParams();
    });
  }, []);

  const generateStep = (st) => {
    switch (st) {
      case 0:
        return (
          <p className={styles.modalText}>
            You don't have Metamask installed!
          </p>
        );

      case 1:
        return (
          <p className={styles.modalText}>
            You haven't connected your account to Metamask Wallet!
          </p>
        );

      case 2:
        return (
          <p className={styles.modalText}>
            You're on a different network. Switch to Sepolia.
          </p>
        );

      case 3:
        return (
          <p className={styles.modalText}>
            Oops, you don't have ETHs tokens in your account
          </p>
        );

      default:
        return <p className={styles.modalText}>Good to go!</p>;
    }
  };

  Modal.setAppElement('#root');

  return (
    <Modal
      isOpen={modalIsOpen}
      className={`absolute inset-0 ${styles.flexCenter} flex-col ${styles.glassEffect}`}
      overlayClassName="Overlay"
      //ariaHideApp={false}
    >
      {generateStep(step)}
    </Modal>
  );
};

export default OnboardModal;
