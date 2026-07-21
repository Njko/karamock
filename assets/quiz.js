// Shared quiz component for the KaraFun UI-clone lessons.
// Markup contract:
// <div class="quiz" data-answer="a">                          <!-- multiple choice: data-answer = option value -->
//   <p class="quiz-question">...</p>
//   <label><input type="radio" name="qN" value="a"> ...</label>
//   ...
//   <button class="quiz-check">Vérifier</button>
//   <p class="quiz-feedback"></p>
// </div>
//
// <div class="quiz" data-answer="foo|bar">                    <!-- free text: pipe-separated accepted answers -->
//   <p class="quiz-question">...</p>
//   <input type="text">
//   <button class="quiz-check">Vérifier</button>
//   <p class="quiz-feedback"></p>
// </div>

document.addEventListener('click', function (e) {
  if (!e.target.matches('.quiz-check')) return;

  const quiz = e.target.closest('.quiz');
  if (!quiz) return;

  const feedback = quiz.querySelector('.quiz-feedback');
  const rawAnswer = (quiz.dataset.answer || '').trim().toLowerCase();
  const accepted = rawAnswer.split('|').map(function (s) { return s.trim(); }).filter(Boolean);

  const radios = quiz.querySelectorAll('input[type="radio"]');
  const textInput = quiz.querySelector('input[type="text"]');

  let given = null;

  if (radios.length) {
    const checked = quiz.querySelector('input[type="radio"]:checked');
    given = checked ? checked.value.trim().toLowerCase() : null;
  } else if (textInput) {
    given = textInput.value.trim().toLowerCase();
  }

  if (!given) {
    feedback.textContent = 'Choisis ou saisis une réponse avant de vérifier.';
    feedback.className = 'quiz-feedback quiz-feedback--neutral';
    return;
  }

  const correct = accepted.indexOf(given) !== -1;

  quiz.classList.toggle('quiz--correct', correct);
  quiz.classList.toggle('quiz--incorrect', !correct);

  feedback.textContent = correct
    ? '✓ Exact.'
    : '✗ Pas tout à fait — relis l’encadré au-dessus et réessaie.';
  feedback.className = 'quiz-feedback ' + (correct ? 'quiz-feedback--correct' : 'quiz-feedback--incorrect');
});

document.addEventListener('keydown', function (e) {
  if (e.key !== 'Enter') return;
  const input = e.target;
  if (!input.matches('.quiz input[type="text"]')) return;
  const quiz = input.closest('.quiz');
  const btn = quiz && quiz.querySelector('.quiz-check');
  if (btn) { e.preventDefault(); btn.click(); }
});
