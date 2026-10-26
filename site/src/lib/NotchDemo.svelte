<script lang="ts">
  import { demo } from './content';

  /** The stage has a fixed size (904 x 565) and is scaled to the width of its container. */
  let width = $state(0);
</script>

<!-- A looping illustration of the app: hover over the notch, ask, get an answer, fold away.
     It is drawn in HTML and CSS (no video) and is replaced by static/demo.gif when that file exists. -->
<div class="viewport" bind:clientWidth={width} style:--s={width / 904} class:ready={width > 0} role="img" aria-label={demo.alt}>
  <div class="stage" aria-hidden="true">
    <div class="menubar">
      <span class="item" style="width: 44px"></span>
      <span class="item" style="width: 62px"></span>
      <span class="item" style="width: 52px"></span>
      <span class="spacer"></span>
      <span class="item" style="width: 20px"></span>
      <span class="item" style="width: 20px"></span>
      <span class="item" style="width: 70px"></span>
    </div>

    <div class="notch">
      <div class="panel">
        <div class="messages">
          <div class="user">
            <span class="bubble"><span class="typed">Draft a polite reply saying I'm running late.</span></span>
          </div>
          <div class="assistant">
            <span class="dots"><i></i><i></i><i></i></span>
            <p class="line l1"><span>Hi! I'm running about ten minutes late.</span></p>
            <p class="line l2"><span>Sorry for the wait, see you soon.</span></p>
          </div>
        </div>
        <div class="input">
          <span>Type a message…</span>
          <b></b>
        </div>
      </div>
    </div>

    <svg class="cursor" width="22" height="26" viewBox="0 0 22 26" fill="none">
      <path d="M3 2v19l5-4.5 3.4 7.6 3.2-1.5-3.3-7.4H19L3 2Z" fill="#fff" stroke="#0b0c11" stroke-width="1.6" stroke-linejoin="round" />
    </svg>
  </div>
</div>

<style>
  .viewport {
    position: relative;
    width: 100%;
    height: 100%;
    overflow: hidden;
    background:
      radial-gradient(80% 90% at 15% 0%, rgba(59, 98, 232, 0.55), transparent 65%),
      radial-gradient(70% 80% at 100% 100%, rgba(106, 44, 245, 0.35), transparent 70%), #0e1018;
  }

  .stage {
    position: absolute;
    top: 0;
    left: 0;
    width: 904px;
    height: 565px;
    transform: scale(var(--s, 1));
    transform-origin: 0 0;
    opacity: 0;
    font-family: var(--font-sans);
    --loop: 14s;
  }
  .viewport.ready .stage {
    opacity: 1;
  }

  /* Every animated part shares the loop length so the timeline stays in sync. */
  .notch,
  .panel,
  .cursor,
  .bubble,
  .typed,
  .dots,
  .line span {
    animation-duration: var(--loop);
    animation-iteration-count: infinite;
  }

  .menubar {
    position: absolute;
    inset: 0 0 auto 0;
    height: 30px;
    display: flex;
    align-items: center;
    gap: 14px;
    padding: 0 18px;
    background: rgba(8, 9, 14, 0.35);
  }
  .menubar .item {
    height: 8px;
    border-radius: 4px;
    background: rgba(255, 255, 255, 0.22);
  }
  .menubar .spacer {
    flex: 1;
  }

  .notch {
    position: absolute;
    top: 0;
    left: 50%;
    width: 190px;
    height: 30px;
    transform: translateX(-50%);
    border-radius: 0 0 18px 18px;
    background: #050507;
    overflow: hidden;
    animation-name: notch;
  }
  @keyframes notch {
    0%,
    21% {
      width: 190px;
      height: 30px;
      border-radius: 0 0 18px 18px;
      animation-timing-function: cubic-bezier(0.16, 1, 0.3, 1);
    }
    31%,
    90% {
      width: 560px;
      height: 360px;
      border-radius: 0 0 34px 34px;
      animation-timing-function: cubic-bezier(0.5, 0, 0.2, 1);
    }
    97%,
    100% {
      width: 190px;
      height: 30px;
      border-radius: 0 0 18px 18px;
    }
  }

  .panel {
    position: absolute;
    inset: 0;
    width: 560px;
    left: 50%;
    transform: translateX(-50%);
    opacity: 0;
    animation-name: panel;
  }
  @keyframes panel {
    0%,
    27% {
      opacity: 0;
    }
    34%,
    89% {
      opacity: 1;
    }
    93%,
    100% {
      opacity: 0;
    }
  }

  .messages {
    position: absolute;
    inset: 52px 24px auto 24px;
    color: #f2f3f8;
    font-size: 15px;
    line-height: 1.45;
  }
  .user {
    display: flex;
    justify-content: flex-end;
  }
  .bubble {
    display: inline-block;
    padding: 9px 14px;
    border-radius: 16px;
    background: #3b62e8;
    opacity: 0;
    animation-name: bubble;
  }
  @keyframes bubble {
    0%,
    34% {
      opacity: 0;
      transform: translateY(8px);
    }
    36%,
    89% {
      opacity: 1;
      transform: none;
    }
    93%,
    100% {
      opacity: 0;
    }
  }
  .typed {
    display: inline-block;
    width: 0;
    overflow: hidden;
    white-space: nowrap;
    vertical-align: bottom;
    animation-name: typed;
  }
  @keyframes typed {
    0%,
    36% {
      width: 0;
      animation-timing-function: steps(45);
    }
    47%,
    96% {
      width: 328px;
    }
    97%,
    100% {
      width: 0;
    }
  }

  .assistant {
    position: relative;
    height: 62px;
    margin-top: 20px;
  }
  .dots {
    position: absolute;
    top: 8px;
    left: 0;
    display: flex;
    gap: 5px;
    opacity: 0;
    animation-name: dots;
  }
  .dots i {
    width: 7px;
    height: 7px;
    border-radius: 50%;
    background: #9ca2b5;
    animation: blink 1s ease-in-out infinite;
  }
  .dots i:nth-child(2) {
    animation-delay: 0.15s;
  }
  .dots i:nth-child(3) {
    animation-delay: 0.3s;
  }
  @keyframes dots {
    0%,
    47% {
      opacity: 0;
    }
    48%,
    51% {
      opacity: 1;
    }
    52%,
    100% {
      opacity: 0;
    }
  }
  @keyframes blink {
    0%,
    100% {
      opacity: 0.3;
    }
    50% {
      opacity: 1;
    }
  }

  .line {
    position: absolute;
    left: 0;
    margin: 0;
    white-space: nowrap;
  }
  .l1 {
    top: 0;
  }
  .l2 {
    top: 28px;
  }
  .line span {
    display: inline-block;
    width: 0;
    overflow: hidden;
    vertical-align: bottom;
  }
  .l1 span {
    animation-name: line1;
  }
  .l2 span {
    animation-name: line2;
  }
  @keyframes line1 {
    0%,
    51% {
      width: 0;
      animation-timing-function: steps(39);
    }
    61%,
    96% {
      width: 300px;
    }
    97%,
    100% {
      width: 0;
    }
  }
  @keyframes line2 {
    0%,
    61% {
      width: 0;
      animation-timing-function: steps(33);
    }
    69%,
    96% {
      width: 260px;
    }
    97%,
    100% {
      width: 0;
    }
  }

  .input {
    position: absolute;
    left: 24px;
    right: 24px;
    bottom: 18px;
    height: 44px;
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 6px 0 18px;
    border-radius: 22px;
    background: #1c1d24;
    color: #7c8195;
    font-size: 14px;
  }
  .input b {
    width: 32px;
    height: 32px;
    border-radius: 50%;
    background: #3b62e8;
  }

  .cursor {
    position: absolute;
    top: 0;
    left: 0;
    opacity: 0;
    animation-name: cursor;
    filter: drop-shadow(0 2px 4px rgba(0, 0, 0, 0.5));
  }
  @keyframes cursor {
    0% {
      opacity: 0;
      transform: translate(780px, 480px);
    }
    4% {
      opacity: 1;
      transform: translate(780px, 480px);
      animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    }
    20%,
    23% {
      opacity: 1;
      transform: translate(462px, 24px);
      animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    }
    32%,
    83% {
      opacity: 1;
      transform: translate(640px, 210px);
      animation-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
    }
    90% {
      opacity: 1;
      transform: translate(830px, 480px);
    }
    93%,
    100% {
      opacity: 0;
      transform: translate(830px, 480px);
    }
  }

  /* Reduced motion: show the finished state instead of looping. */
  @media (prefers-reduced-motion: reduce) {
    .notch,
    .panel,
    .cursor,
    .bubble,
    .typed,
    .dots,
    .line span {
      animation: none;
    }
    .notch {
      width: 560px;
      height: 360px;
      border-radius: 0 0 34px 34px;
    }
    .panel,
    .bubble {
      opacity: 1;
    }
    .typed {
      width: 328px;
    }
    .l1 span {
      width: 300px;
    }
    .l2 span {
      width: 260px;
    }
    .dots,
    .cursor {
      display: none;
    }
  }
</style>
