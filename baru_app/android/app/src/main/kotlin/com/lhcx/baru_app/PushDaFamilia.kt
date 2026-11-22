package com.lhcx.baru_app

import com.google.firebase.messaging.FirebaseMessagingService
import com.google.firebase.messaging.RemoteMessage

/**
 * Push do Firebase no celular do responsável (Android). O servidor manda só
 * dados (prioridade alta): assim o Baru monta o aviso, e o SOS toca o alarme
 * insistente do canal próprio, mesmo com o app fechado.
 */
class PushDaFamilia : FirebaseMessagingService() {
    override fun onMessageReceived(m: RemoteMessage) {
        if (m.data["baru"] == "aviso") AvisosDaFamilia.doPush(this, m.data)
    }

    override fun onNewToken(token: String) {
        AvisosDaFamilia.registraToken(this, token)
    }
}
