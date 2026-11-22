/// Textos da foto de perfil.
library;

import 'l10n.dart';

void garanteTextosDaFoto() => T.registra(textosDaFoto);

const textosDaFoto = <String, Map<String, String>>{
  'pt': {
    'fotoT': 'Foto de perfil',
    'fotoCamera': 'Tirar foto',
    'fotoGaleria': 'Escolher da galeria',
    'fotoRemover': 'Remover foto',
    'fotoPronta': 'Foto atualizada.',
    'fotoFalhou': 'Não deu para trocar a foto. Tente de novo.',
    'fotoTrocar': 'Trocar foto',
  },
  'en': {
    'fotoT': 'Profile photo',
    'fotoCamera': 'Take photo',
    'fotoGaleria': 'Choose from gallery',
    'fotoRemover': 'Remove photo',
    'fotoPronta': 'Photo updated.',
    'fotoFalhou': 'Could not change the photo. Try again.',
    'fotoTrocar': 'Change photo',
  },
  'es': {
    'fotoT': 'Foto de perfil',
    'fotoCamera': 'Tomar foto',
    'fotoGaleria': 'Elegir de la galería',
    'fotoRemover': 'Quitar foto',
    'fotoPronta': 'Foto actualizada.',
    'fotoFalhou': 'No se pudo cambiar la foto. Inténtalo de nuevo.',
    'fotoTrocar': 'Cambiar foto',
  },
  'zh': {
    'fotoT': '头像',
    'fotoCamera': '拍照',
    'fotoGaleria': '从相册选择',
    'fotoRemover': '删除头像',
    'fotoPronta': '头像已更新。',
    'fotoFalhou': '无法更换头像，请重试。',
    'fotoTrocar': '更换头像',
  },
};
