// ヘルプリンクを条件に応じて非表示にする
function hideHelp() {
  const buttonHelp = document.querySelector('.btn-help');
  const checkCountContainer = document.getElementById("check-count-box");

  const footer = document.querySelector('footer').offsetHeight; // footerの高さを取得

  // ヘルプのポップアップがフッターに被るタイミングでポップアップを非表示にする
  if (buttonHelp) {
    window.onscroll = function() {
      const point = window.scrollY; // 現在のスクロール地点
      const docHeight = Math.max(
        document.body.scrollHeight, document.documentElement.scrollHeight,
        document.body.offsetHeight, document.documentElement.offsetHeight,
        document.body.clientHeight, document.documentElement.clientHeight
      ); // ドキュメントの高さ
      const dispHeight = window.innerHeight; // 表示領域の高さ

      if (point > docHeight - dispHeight - footer) { // スクロール地点 > ドキュメントの高さ - 表示領域 - footerの高さ
        buttonHelp.classList.add('is-hidden'); // footerより下にスクロールしたらis-hiddenを追加
      } else {
        buttonHelp.classList.remove('is-hidden'); // footerより上にスクロールしたらis-hiddenを削除
      }
    }

    // お買い物登録でアイテムがチェックされている時はヘルプのポップアップを非表示にする
    if (checkCountContainer) {
      function hideHelpByCheck() {
        const clickPoint = document.getElementsByName("checkbox_click_point");

        if (checkCountContainer.classList.contains('d-none')) {
          buttonHelp.classList.remove('d-none');
        } else {
          buttonHelp.classList.add('d-none');
        }

        for(let i = 0; i < clickPoint.length; i++) {
          clickPoint[i].addEventListener('click', hideHelpByCheck);
        }

        document.getElementById("check_reset_button").addEventListener('click', hideHelpByCheck);
      }

      hideHelpByCheck();
    }
  }
}

document.addEventListener('turbo:load', hideHelp);
document.addEventListener('turbo:render', hideHelp);
