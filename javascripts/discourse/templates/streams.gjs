import StreamsPage from "../components/streams-page";

export default <template>
  <StreamsPage @initialModel={{if this.model this.model @model}} />
</template>;
