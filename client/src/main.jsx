import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter, Route, Routes } from 'react-router-dom';

import { GlobalContextProvider } from './context';
import './index.css';
import { Home, Game, StartGame, JoinGame } from './page';
import { OnboardModal } from './components';

ReactDOM.createRoot(document.getElementById('root')).render(
  <BrowserRouter>
    <GlobalContextProvider>
      <OnboardModal />
        <Routes>
          <Route path="/" element={<Home />} />
          <Route path="/start-game" element={<StartGame />} />
          <Route path="/game/:gameName" element={<Game />} />
          <Route path="/join-game" element={<JoinGame />} />
        </Routes>
      
    </GlobalContextProvider>
  </BrowserRouter>
  ,
);
